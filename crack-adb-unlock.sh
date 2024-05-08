#!/bin/bash

echo "> Montando partições Andriod...";
adb remount &&
echo "> Montado!";
echo "> Habilitando USB...";
adb push ./persist.sys.usb.config /data/property &&
echo "> Habilitado!";
echo "> Ativando depuração...";
adb push ~/.android/adbkey.pub /data/misc/adb/adb_keys &&
adb shell "echo -e '\n# It was added by Crack-ADB-Unlock:\npersist.service.adb.enable=1\npersist.service.debuggable=1\npersist.sys.usb.config=mtp,adb' >> /system/build.prop" &&
echo "> Depuração ativada com sucesso! \n> Bye! " 



