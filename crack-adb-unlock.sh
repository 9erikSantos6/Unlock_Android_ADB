#!/bin/bash

adb shell umount data && sleep "1" && 
adb shell mount data && sleep "1" &&
adb shell umount system && sleep "1" &&
adb shell mount system && sleep "1" &&
adb push ./persist.sys.usb.config /data/property && sleep "1" &&
adb shell echo "\n# Adcicionado pelo script:\npersist.service.adb.enable=1\npersist.service.debuggable=1\npersist.sys.usb.config=mtp,adb" >> /system/build.prop
# adb push ./build.prop /system/ 
