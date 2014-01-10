# Build script for EvoThings client app.
#
# Possible switches are "c" (clean) and "i" (install).
# Examples:
#   ruby workfile.rb
#   ruby workfile.rb i
#   ruby workfile.rb c i

require 'fileutils'
require './utils.rb'

include FileUtils::Verbose

mkdir_p 'platforms'
mkdir_p 'plugins'

# Cordova Android version hack:
#
# Update: On Cordova 3.3 this does not seem to be an issue, as android-19 is used.
#
# You may have to edit android_parser.js to update the Android platform
# level to refer to at least android-18 (needed for BLE).
# Windows:
#   AppData\Roaming\npm\node_modules\cordova\src\metadata\android_parser.js
# OS X:
#   /usr/local/lib/node_modules/cordova/src/metadata/android_parser.js
#
# Alternatively, if you have an existing Cordova Android existing project
# you wish to update, edit the following files:
#   platforms/android/project.properties (update to: target=android-18)
#   platforms/android/AndroidManifest.xml (update to: android:targetSdkVersion="18")

# Remove platform(s) if switch "c" (clean) is given.
if(ARGV[0] == 'c' || ARGV[1] == 'c')
	sh 'cordova -d platform remove android'
end

if(!File.exist?('platforms/android'))
	sh 'cordova -d platform add android'
end

def addPlugin(name, location = name)
	if(!File.exist?("plugins/#{name}"))
		sh "cordova -d plugin add #{location}"
	end
end

addPlugin('org.apache.cordova.battery-status')
addPlugin('org.apache.cordova.camera')
addPlugin('org.apache.cordova.console')
addPlugin('org.apache.cordova.contacts')
addPlugin('org.apache.cordova.device')
addPlugin('org.apache.cordova.device-motion')
addPlugin('org.apache.cordova.device-orientation')
addPlugin('org.apache.cordova.dialogs')
addPlugin('org.apache.cordova.file')
addPlugin('org.apache.cordova.file-transfer')
addPlugin('org.apache.cordova.geolocation')
addPlugin('org.apache.cordova.globalization')
addPlugin('org.apache.cordova.inappbrowser')
addPlugin('org.apache.cordova.media')
addPlugin('org.apache.cordova.media-capture')
addPlugin('org.apache.cordova.network-information')
# Splashscreen requires adding splashscreen media files to
# the build, and is not meaningful for EvoThings client.
#addPlugin('org.apache.cordova.splashscreen')
addPlugin('org.apache.cordova.vibration')
addPlugin('org.chromium.socket')
addPlugin('com.evothings.ble', '../cordova-ble')

# Copy icon files to platform(s)
begin
	androidIcons = {
		'drawable-ldpi' => 36,
		'drawable-mdpi' => 48,
		'drawable-hdpi' => 72,
		'drawable-xhdpi' => 96,
		'drawable' => 96,
	}
	androidIcons.each do |dest,src|
		srcFile = "config/icons/icon-#{src}.png"
		destFile = "platforms/android/res/#{dest}/icon.png"
		# Removed uptodate? check because it fails when existing
		# dest icons are newer than then source icons (which happens
		# when cleaning the project by deleting and adding a platform).
		#if(!uptodate?(destFile, [srcFile]))
			cp(srcFile, destFile)
		#end
	end
end

# Copy native source files to platform(s)
begin
	srcFile = "config/native/android/src/com/evothings/evothingsclient/EvoThings.java"
	destFile = "platforms/android/src/com/evothings/evothingsclient/EvoThings.java"
	cp(srcFile, destFile)
end

# Build platform(s)
sh 'cordova build android'

# Install debug build if switch "i" is given.
if(ARGV[0] == 'i' || ARGV[1] == 'i')
	sh 'adb install -r platforms/android/bin/EvoThings-debug.apk'
end
