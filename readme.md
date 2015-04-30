##Evothings Client

This is the companion app to [Evothings Studio](https://github.com/evothings/EvoThingsStudio).

It consists of a Cordova WebView, a bunch of useful plugins, and an intro page that allows you to find and connect to nearby Studio instances.


### Building the Client

Dependencies

- Ruby and the Ruby gem 'redcarpet' (gem install redcarpet)
- Check out the evothings/examples project at the same top level directory as the evothings-client project.

Run the Ruby script 'workfile.rb'. It generates files, initializes the Cordova project, fetches plugins, builds the app, and, optionally, installs it on a connected device.
