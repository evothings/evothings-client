#!/bin/bash
#
# Script that adds Cordova plugins
echo "Adding Cordova Plugins"
#
# Good to have:
# chmod u+x cordova-plugins.sh
# cordova create EvoThingsClient com.evothings.evothingsclient "EvoThings"
# cordova platform add ios
# cordova platform add android
#
cordova plugin add org.apache.cordova.battery-status
cordova plugin add org.apache.cordova.camera
cordova plugin add org.apache.cordova.console
cordova plugin add org.apache.cordova.contacts
cordova plugin add org.apache.cordova.device
cordova plugin add org.apache.cordova.device-motion
cordova plugin add org.apache.cordova.device-orientation
cordova plugin add org.apache.cordova.dialogs
cordova plugin add org.apache.cordova.file
cordova plugin add org.apache.cordova.file-transfer
cordova plugin add org.apache.cordova.geolocation
cordova plugin add org.apache.cordova.globalization
cordova plugin add org.apache.cordova.inappbrowser
cordova plugin add org.apache.cordova.media
cordova plugin add org.apache.cordova.media-capture
cordova plugin add org.apache.cordova.network-information
#cordova plugin add org.apache.cordova.splashscreen
cordova plugin add org.apache.cordova.vibration
cordova plugin add org.chromium.socket
cordova plugin add ../cordova-ble/
#com.contraterrene.gapfile
#org.devgeeks.canvas2imageplugin
