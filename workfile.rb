# Build script for Evothings client app.
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
#   ruby workfile.rb ios
#   ruby workfile.rb c ios

require "fileutils"
require "./utils.rb"

include FileUtils::Verbose

# Load localConfig.rb, if it exists. This file
# contains configuration settings.
lc = "#{File.dirname(__FILE__)}/localConfig.rb"
require lc if(File.exists?(lc))

# Build command parameters.
# Default platform is Android.
@platform = "android"
@clean = false
@install = false

def parseCommandParameters
	if(defined?(CONFIG_DEFAULT_PLATFORM))
		@platform = CONFIG_DEFAULT_PLATFORM
	end

	ARGV.each do |arg|
		case (arg)
			when "c"
				@clean = true
			when "i"
				@install = true
			when "android", "wp8", "ios"
				@platform = arg
			else raise "Invalid argument #{arg}"
		end
	end
end

def createDirectories
	mkdir_p "platforms"
	mkdir_p "plugins"
end

def addPlugins
	def addPlugin(name, location = name)
		if(!File.exist?("plugins/#{name}"))
			sh "cordova -d plugin add #{location}"
		end
	end

	addPlugin("org.apache.cordova.battery-status")
	addPlugin("org.apache.cordova.camera")
	addPlugin("org.apache.cordova.console")
	addPlugin("org.apache.cordova.contacts")
	addPlugin("org.apache.cordova.device")
	addPlugin("org.apache.cordova.device-motion")
	addPlugin("org.apache.cordova.device-orientation")
	addPlugin("org.apache.cordova.dialogs")
	addPlugin("org.apache.cordova.file")
	addPlugin("org.apache.cordova.file-transfer")
	addPlugin("org.apache.cordova.geolocation")
	addPlugin("org.apache.cordova.globalization")
	addPlugin("org.apache.cordova.inappbrowser")
	addPlugin("org.apache.cordova.media")
	addPlugin("org.apache.cordova.media-capture")
	addPlugin("org.apache.cordova.network-information")
	# Splashscreen requires adding splashscreen media files to
	# the build, and is not meaningful for Evothings client.
	#addPlugin("org.apache.cordova.splashscreen")
	addPlugin("org.apache.cordova.vibration")
	if(defined?(CONFIG_CHROME_SOCKET_DIR))
		addPlugin("org.chromium.socket", CONFIG_CHROME_SOCKET_DIR)
	else
		addPlugin("org.chromium.socket")
	end
	addPlugin("com.evothings.ble", "../cordova-ble")
	addPlugin("org.apache.cordova.ibeacon", "../cordova-plugin-ibeacon")

	# Classic Bluetooth for Android.
	if (@platform == "android")
		addPlugin("com.megster.cordova.bluetoothserial", "https://github.com/don/BluetoothSerial.git")
	end

	# Should we ship the SMS plugin?
	# Commenting out the plugin for now.
	#if(@platform == "wp8")
	#	addPlugin("com.evothings.ble", "../phonegap-sms-plugin")
	#end
end

def fileRead(filePath)
	File.open(filePath, "r") { |f|
		s = f.read
		if(RUBY_VERSION >= '1.9')
			return s.force_encoding("UTF-8")
		else
			return s
		end
	}
end

def fileSave(destFile, content)
	File.open(destFile, "w") { |f| f.write(content) }
end

# Read version number from config.xml
def readVersionNumber
	config = fileRead("./www/config.xml")

	# Get version number from config.xml.
	versionMatch = config.scan(/version="(.*?)"/)
	if(versionMatch.empty?)
		error "Version not found in config.xml!"
	end

	return versionMatch[0][0]
end

def readGitInfo(name, location)
	oldDir = pwd
	cd location
	rp = "git rev-parse HEAD"
	sh rp	# make sure the command doesn't fail; open() doesn't do that.
	hash = open("|#{rp}").read.strip
	ss = "git status -s"
	sh ss
	mod = open("|#{ss}").read.strip
	if(mod != "")
		mod = " modified"
	end
	cd oldDir
	# Git version string contains: name, hash, modified flag
	gitInfo = "#{name}: #{hash[0,8]}#{mod}"
	return gitInfo
end

# Create www/index.html with version into.
# This file is used in the Cordova build process.
def createIndexFileWithVersionInfo
	index = fileRead("config/www/index.html")
	version = readVersionNumber()
	gitInfo = readGitInfo("EvoThingsClient", ".")
	versionString = "#{version}<br/>\n#{gitInfo}<br/>\n"
	if(!index.gsub!("<version>", versionString))
		error "Could not find <version> in #{src}"
	end
	fileSave("www/index.html", index)
end

def copyIconsAndPlatformFiles
	# Copy Android icon files to native project.
	if(@platform == "android")
		androidIcons = {
			"drawable-ldpi" => 36,
			"drawable-mdpi" => 48,
			"drawable-hdpi" => 72,
			"drawable-xhdpi" => 96,
			"drawable" => 96,
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

	# Copy iOS icon files to native project.
	# For info about iOS app icons, see:
	# https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/App-RelatedResources/App-RelatedResources.html#//apple_ref/doc/uid/TP40007072-CH6-SW1
	if(@platform == "ios")
		srcPath = "config/icons/"
		destPath = "platforms/ios/EvoThings/Resources/icons/"

		# Delete old icons.
		FileUtils.rm_rf(Dir.glob(destPath + "*"))

		copyIOSIcon = lambda do |src, dest|
			cp(srcPath + src, destPath + dest)
		end

		copyIOSIcon.call("icon-white-29.png", "icon-small.png")
		copyIOSIcon.call("icon-white-40.png", "icon-40.png")
		copyIOSIcon.call("icon-white-50.png", "icon-50.png")
		copyIOSIcon.call("icon-white-57.png", "icon.png")
		copyIOSIcon.call("icon-white-58.png", "icon-small@2x.png")
		copyIOSIcon.call("icon-white-80.png", "icon-40@2x.png")
		copyIOSIcon.call("icon-white-60.png", "icon-60.png")
		copyIOSIcon.call("icon-white-100.png", "icon-50@2x.png")
		copyIOSIcon.call("icon-white-114.png", "icon@2x.png")
		copyIOSIcon.call("icon-white-120.png", "icon-60@2x.png")
		copyIOSIcon.call("icon-white-72.png", "icon-72.png")
		copyIOSIcon.call("icon-white-76.png", "icon-76.png")
		copyIOSIcon.call("icon-white-144.png", "icon-72@2x.png")
		copyIOSIcon.call("icon-white-152.png", "icon-76@2x.png")
	end

	# Copy iOS splash screens.
	if(@platform == "ios")
		srcPath = "config/icons/ios_splash"
		destPath = "platforms/ios/EvoThings/Resources/splash"
		FileUtils.copy_entry(srcPath, destPath)
	end

	# Copy native Android source files.
	if(@platform == "android")
		cp("config/native/android/src/com/evothings/evothingsclient/Evothings.java",
			"platforms/android/src/com/evothings/evothingsclient/Evothings.java")

		# TODO: edit the cordova-generated file instead.
		cp("config/native/android/AndroidManifest.xml",
			"platforms/android/AndroidManifest.xml")
	end

	# Copy native iOS source files.
	if(@platform == "ios")
		cp("config/native/ios/main.m", "platforms/ios/EvoThings/main.m")
		cp("config/native/ios/EvoThings-Info.plist", "platforms/ios/EvoThings/EvoThings-Info.plist")

		# According to the page below, this patch in shipped in the most recent Cordova 3.4.1
		# Commented out patch for now.
		# Patch for Cordova 3.4 and iOS 7.1 (remove when upgrading to Cordova 3.5)
		# http://shazronatadobe.wordpress.com/2014/03/12/xcode-5-1-and-cordova-ios/
		#cp("config/native/ios/CDVCommandQueue.m", "platforms/ios/CordovaLib/Classes/CDVCommandQueue.m")
		#cp("config/native/ios/CDVViewController.m", "platforms/ios/CordovaLib/Classes/CDVViewController.m")
	end
end

def build
	# Get command line parameters.
	parseCommandParameters

	# Remove platform(s) if switch "c" (clean) is given.
	if(@clean)
		sh "cordova -d platform remove #{@platform}"
	end

	# Create www/index.html with current version info.
	createIndexFileWithVersionInfo

	# Create directories required for the build.
	createDirectories

	# Add target platform if not present.
	if(!File.exist?("platforms/#{@platform}"))
		sh "cordova -d platform add #{@platform}"
	end

	# Copy icon files and native project files.
	copyIconsAndPlatformFiles

	# Add all plugins.
	addPlugins

	# Build platform.
	sh "cordova build #{@platform}"

	# Install debug build if switch "i" is given.
	if(@install && @platform == "android")
		sh "adb install -r platforms/android/ant-build/Evothings-debug.apk"
	end
end

build
