#!/bin/bash
# Wgrywanie blacklist ze strony http://zabojcaspamu.pl
# 
# v0.1 2018-02-11 Start script

# Katalog tymaczasowy do policzenia sumy kontrolnej 
WORK_DIR="/tmp"
# Katalog docelowy z ktorego zaczytuje reguly SA
SAVE_DIR="/etc/spamassassin"
# Log z dzialanai skryptu
LOG_FILE="/var/log/zabojcaspamu.log"

#
#
#
FILE_BL=(local.cf.BL.ZABOJCASPAMU local.cf.BL.SPAMTRAP)

for FILE in ${FILE_BL[*]};do
    SIGN_DATA="[$(date +%Y-%m-%d_%H:%m:%S)]"
    curl -s https://zabojcaspamu.pl/$FILE_BL -o ${WORK_DIR}/${FILE_BL}
    RETV=$?
    if [ "$RETV" -ne "0" ];then
       echo "$SIGN_DATA Blad podczas sciagania pliku" >> ${LOG_FILE}
       exit 1
    fi
    SUMA=`curl -s https://zabojcaspamu.pl/md5sum.txt|grep  $FILE_BL|awk '{print $1}'`
    echo "$SUMA ${WORK_DIR}/${FILE_BL}" | md5sum -c - >/dev/null
    RETV=$?
    if [ "$RETV" -ne "0" ];then
       echo "$SIGN_DATA Plik $PLIK sciagniety ale suma kontrola sie nie zgadza"  >> ${LOG_FILE}
       exit 1
    fi

    cp -f ${WORK_DIR}/${FILE_BL} ${SAVE_DIR}/${FILE_BL} 2>/dev/null
    RETV=$?
    if [ "$RETV" -ne "0" ];then
       echo "$SIGN_DATA Plik $PLIK sciagniety suma kontrola OK ale przegranie do $SAVE_DIR katalogu sie nie powiodlo"  >> ${LOG_FILE}
       exit 1
    fi

    echo "$SIGN_DATA  Plik $FILE sciagniety i wgrany prawidlowo do $SAVE_DIR"  >> ${LOG_FILE}
done

