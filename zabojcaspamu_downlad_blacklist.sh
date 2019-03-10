#!/bin/bash
# Wgrywanie blacklist ze strony http://zabojcaspamu.pl
# 
# v0.2 2018-07-02 Start script
# https://zabojcaspamu.pl/program-sciagania-blacklist/

# Katalog tymaczasowy do policzenia sumy kontrolnej 
WORK_DIR="/tmp"
# Katalog docelowy z ktorego zaczytuje reguly SA
SAVE_DIR="/etc/spamassassin"
# Log z dzialania skryptu
LOG_FILE="/var/log/zabojcaspamu.log"

#
#
#
FILE_BL=(local.cf.BL.ZABOJCASPAMU local.cf.BL.SPAMTRAP local.cf.reguly.ZABOJCASPAMU)

for FILE in ${FILE_BL[*]};do
    SIGN_DATA="[$(date +%Y-%m-%d_%H:%M:%S)]"
    curl -s https://zabojcaspamu.pl/$FILE -o ${WORK_DIR}/${FILE}
    RETV=$?
    if [ "$RETV" -ne "0" ];then
       echo "$SIGN_DATA Blad podczas sciagania pliku" >> ${LOG_FILE}
       exit 1
    fi
    SUMA=`curl -s https://zabojcaspamu.pl/md5sum.txt|grep  $FILE|awk '{print $1}'`
    echo "$SUMA ${WORK_DIR}/${FILE}" | md5sum -c - >/dev/null
    RETV=$?
    if [ "$RETV" -ne "0" ];then
       echo "$SIGN_DATA Plik $FILE sciagniety ale suma kontrola sie nie zgadza"  >> ${LOG_FILE}
       exit 1
    fi

    cp -f ${WORK_DIR}/${FILE} ${SAVE_DIR}/${FILE} 2>/dev/null
    RETV=$?
    if [ "$RETV" -ne "0" ];then
       echo "$SIGN_DATA Plik $FILE sciagniety suma kontrola OK ale przegranie do $SAVE_DIR katalogu sie nie powiodlo"  >> ${LOG_FILE}
       exit 1
    fi

    echo "$SIGN_DATA  Plik $FILE sciagniety i wgrany prawidlowo do $SAVE_DIR"  >> ${LOG_FILE}
done

