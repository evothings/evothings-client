require 'fileutils'
require './utils.rb'

include FileUtils::Verbose

mkdir_p 'platforms'

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

# need to change target android version from 17 to 18 now.
# edit project.properties and AndroidManifest.xml.

sh 'cordova build android'
