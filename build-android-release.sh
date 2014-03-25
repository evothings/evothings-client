#!/bin/bash
#
# Script that builds Android release apk
#
# Make shell script executable:
#   chmod u+x build-android-release.sh
# Create a signing key
#   keytool -genkey -v -keystore evothings.keystore -alias evothings_alias -keyalg RSA -keysize 2048 -validity 365000
#
echo "Building Android release APK"
cordova build android --release
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ../keys/evothings.keystore platforms/android/bin/EvoThings-release-unsigned.apk evothings_alias
jarsigner -verify -verbose platforms/android/bin/EvoThings-release-unsigned.apk
zipalign -v 4 platforms/android/bin/EvoThings-release-unsigned.apk platforms/android/bin/EvoThings.apk
