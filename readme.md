##Evothings Client

This is the companion app to [Evothings Studio](https://github.com/evothings/EvoThingsStudio).

It consists of a Cordova WebView, a bunch of useful plugins, and an intro page that allows you to find and connect to nearby Studio instances.


### Building the Client

Dependencies

- Ruby and the Ruby gem 'redcarpet' (gem install redcarpet)
- Check out the evothings/examples project at the same top level directory as the evothings-client project.

Run the Ruby script 'workfile.rb'. It generates files, initializes the Cordova project, fetches plugins, builds the app, and, optionally, installs it on a connected device.


### Installing Cordova
First install node.js. This will give you access to npm.
Then run 'npm install -g cordova@3.6.3-0.2.13'. This should install the last 3.6-based version of Cordova, which we need.
Also required are:
* The Android SDK.
* If you have an version other than 19 (22 is default as of this writing), you must modify the file
  $HOME\.cordova\lib\npm_cache\cordova-android\3.6.3\package\framework\project.properties to contain the correct target.
 * This file is only available once you've run 'cordova platform add android' at least once.
* Apache Ant.
* Java JDK.
* All these must be manually added to your environment variable PATH, so that cordova can use them.
