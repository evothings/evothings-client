#!/bin/bash
#
# Script that builds Android release apk
echo "Building Android release APK"
#
# Good to have:
# chmod u+x build-android-release.sh
# keytool -genkey -v -keystore evothings.keystore -alias evothings_alias -keyalg RSA -keysize 2048 -validity 365000
cordova build android --release
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore evothings.keystore platforms/android/bin/EvoThingsClient-release-unsigned.apk evothings_alias
jarsigner -verify -verbose platforms/android/bin/EvoThingsClient-release-unsigned.apk
zipalign -v 4 platforms/android/bin/EvoThingsClient-release-unsigned.apk platforms/android/bin/EvoThings.apk
