require 'fileutils'
require './utils.rb'

include FileUtils::Verbose

mkdir_p 'platforms'
mkdir_p 'plugins'

# You may have to edit android_parser.js to update the Android platform
# level to refer to at least android-18.
# Windows:
#   AppData\Roaming\npm\node_modules\cordova\src\metadata\android_parser.js
# OS X:
#   /usr/local/lib/node_modules/cordova/src/metadata/android_parser.js
#
# Alternatively, if you have an existing Cordova Android existing project
# you wish to update, edit the following files:
#   platforms/android/project.properties (update to: target=android-18)
#   platforms/android/AndroidManifest.xml (update to: android:targetSdkVersion="18")

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
addPlugin('org.apache.cordova.splashscreen')
addPlugin('org.apache.cordova.vibration')
addPlugin('org.chromium.socket')
addPlugin('com.evothings.ble', '../cordova-ble')

# copy icon files to platform(s)
begin
	androidIcons = {
		'drawable-ldpi' => 36,
		'drawable-mdpi' => 48,
		'drawable-hdpi' => 72,
		'drawable-xhdpi' => 96,
		'drawable' => 96,
	}
	androidIcons.each do |tar,src|
		tarFile = "platforms/android/res/#{tar}/icon.png"
		srcFile = "config/icons/icon-#{src}.png"
		if(!uptodate?(tarFile, [srcFile]))
			cp(srcFile, tarFile)
		end
	end
end

sh 'cordova build android'

if(ARGV[0] == 'i')
	sh 'adb install -r platforms/android/bin/EvoThingsClient-debug.apk'
end
