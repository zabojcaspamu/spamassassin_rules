#!/bin/bash
# Wgrywanie blacklist ze strony http://zabojcaspamu.pl
#
# v0.4 2020-05-16 Start script
# https://zabojcaspamu.pl/program-sciagania-blacklist/
# Poprawki TaKeN.PL
# Katalog tymaczasowy do policzenia sumy kontrolnej
WORK_DIR="/tmp"
# Katalog docelowy z ktorego zaczytuje reguly SA
SAVE_DIR="/etc/spamassassin"
# Log z dzialania skryptu
LOG_FILE="/var/log/zabojcaspamu.log"
# Tu wpisz swoja domene
DOMAIN="taken.pl"
# Proces do restartu po aktualizacji
DAEMON="amavis"
# Plik informujący o koniecznosci restartu.
REBFILE="/tmp/reboot"
#
#
#
FILE_BL=(local.cf.BL.ZABOJCASPAMU local.cf.BL.SPAMTRAP local.cf.reguly.ZABOJCASPAMU)

for FILE in ${FILE_BL[*]};do
    SIGN_DATA="[$(date +%Y-%m-%d_%H:%M:%S)]"
    curl -sL https://zabojcaspamu.pl/$FILE -o ${WORK_DIR}/${FILE}
    RETV=$?
    if [ "$RETV" -ne "0" ];then
        echo "$SIGN_DATA Blad podczas sciagania pliku" >> ${LOG_FILE}
    else
    SUMA=`curl -s https://taken.pl/md5sum.txt|grep $FILE|awk '{print $1}'`
    echo "$SUMA ${WORK_DIR}/${FILE}" | md5sum -c - >/dev/null
    RETV=$?
        if [ "$RETV" -ne "0" ];then
        echo "$SIGN_DATA Plik $FILE sciagniety ale suma kontrola sie nie zgadza" >> ${LOG_FILE}
        else
            if [ "$FILE" = "local.cf.reguly.ZABOJCASPAMU" ]; then
            sed -i 's/WLASNADOMENA/'$DOMAIN'/g' ${WORK_DIR}/${FILE}
            fi
            if cmp -s "${WORK_DIR}/${FILE}" "${SAVE_DIR}/${FILE}" ; then
            echo "$SIGN_DATA Plik $FILE sciagniety ale brak w nim zmian" >> ${LOG_FILE}
            else
            cp -f ${WORK_DIR}/${FILE} ${SAVE_DIR}/${FILE} 2>/dev/null
            RETV=$?
                if [ "$RETV" -ne "0" ];then
                echo "$SIGN_DATA Plik $FILE sciagniety suma kontrola OK ale przegranie do $SAVE_DIR katalogu sie nie powiodlo" >> ${LOG_FILE}
                else
                echo "$SIGN_DATA Plik $FILE sciagniety i wgrany prawidlowo do $SAVE_DIR" >> ${LOG_FILE}
                touch $REBFILE
                fi
            fi
        fi
    fi
done

if [ -f "$REBFILE" ]; then
echo "$SIGN_DATA Zmiana w plikach - restart $DAEMON" >> ${LOG_FILE}
service $DAEMON restart
rm -rf $REBFILE
else
echo "$SIGN_DATA Brak zmian w plikach - restart $DAEMON nie został wykonany" >> ${LOG_FILE}
fi
