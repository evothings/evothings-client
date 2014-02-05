# Build script for EvoThings client app.
#
# Possible switches are:
# c - clean before building
# i - install after building
# android - build Android
# wp8 - build Windows Phone 8
# ios - build iOS
#
# By default, Android will be built.
# Only one platform may be built per invocation.
#
# Examples:
#   ruby workfile.rb
#   ruby workfile.rb i
#   ruby workfile.rb c i

# load localConfig.rb, if it exists.
lc = "#{File.dirname(__FILE__)}/localConfig.rb"
require lc if(File.exists?(lc))

if(!defined?(CONFIG_DEFAULT_PLATFORM))
	CONFIG_DEFAULT_PLATFORM = 'android'
end

# parse ARGV
begin
	c = false
	i = false
	platform = CONFIG_DEFAULT_PLATFORM
	ARGV.each do |arg|
		case (arg)
			when 'c'
				c = true
			when 'i'
				i = true
			when 'android', 'wp8', 'ios'
				platform = arg
			else raise "Invalid argument #{arg}"
		end
	end
	CLEAN = c
	INSTALL = i
	PLATFORM = platform
end

require 'fileutils'
require './utils.rb'

include FileUtils::Verbose

mkdir_p 'platforms'
mkdir_p 'plugins'

def addPlugins
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
	if(PLATFORM == 'wp8')
		addPlugin('com.evothings.ble', '../phonegap-sms-plugin')
	end
end

def build
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
	if(CLEAN)
		sh "cordova -d platform remove #{PLATFORM}"
	end

	if(!File.exist?("platforms/#{PLATFORM}"))
		sh "cordova -d platform add #{PLATFORM}"
	end

	# Copy icon files to platform.
	if(PLATFORM == 'android')
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

	# Copy native source files to platform.
	if(PLATFORM == 'android')
		srcFile = "config/native/android/src/com/evothings/evothingsclient/EvoThings.java"
		destFile = "platforms/android/src/com/evothings/evothingsclient/EvoThings.java"
		cp(srcFile, destFile)
	end

	# Copy native source files to platform.
	if(PLATFORM == 'ios')
		cp("config/native/ios/main.m", "platforms/ios/EvoThings/main.m")
		cp("config/native/ios/URLProtocolCordovaJs.h", "platforms/ios/EvoThings/URLProtocolCordovaJs.h")
		cp("config/native/ios/URLProtocolCordovaJs.m", "platforms/ios/EvoThings/URLProtocolCordovaJs.m")
	end

	# Add all plugins
	addPlugins

	# Build platform.
	sh "cordova build #{PLATFORM}"

	# Install debug build if switch "i" is given.
	if(INSTALL && PLATFORM == 'android')
		sh 'adb install -r platforms/android/bin/EvoThings-debug.apk'
	end
end

build
