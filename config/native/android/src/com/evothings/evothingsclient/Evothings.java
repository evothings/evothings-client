/*
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
 */

package com.evothings.evothingsclient;

import android.content.Intent;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.StrictMode;
import android.util.Log;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;

import java.io.*;
import java.nio.*;
import java.nio.channels.*;
import java.net.URL;
import java.util.Iterator;

import org.apache.cordova.CordovaResourceApi.OpenForReadResult;
import org.apache.cordova.*;

import org.json.*;

public class Evothings extends CordovaActivity
{
	@Override
	public void onCreate(Bundle savedInstanceState)
	{
		if(BuildConfig.DEBUG)
		{
			// Detect all manner of bad things.
			// This code is active only in debug builds.
			/*
			// Cordova does disk access; don't enable this check.
			StrictMode.setThreadPolicy(new StrictMode.ThreadPolicy.Builder()
				.detectAll()
				.penaltyLog()
				.penaltyDeath()
				.build());
			*/
			StrictMode.setVmPolicy(new StrictMode.VmPolicy.Builder()
				.detectAll()
				.penaltyLog()
				.penaltyDeath()
				.build());
		}
		super.onCreate(savedInstanceState);
		super.init();

		// If the intent has a data string we load it.
		Intent intent = getIntent();
		if (isEvothingsIntent(intent))
		{
			openEvothingsIntent(intent);
		}
		else
		{
			// This is the original Cordova page loading code.
			// Set by <content src="index.html" /> in config.xml
			super.loadUrl(Config.getStartUrl());
			//super.loadUrl("file:///android_asset/www/index.html")
		}
	}

	@Override
	protected void onNewIntent(Intent intent)
	{
		if (isEvothingsIntent(intent))
		{
			openEvothingsIntent(intent);
		}
		else
		{
			super.onNewIntent(intent);
		}
	}

	protected boolean isEvothingsIntent(Intent intent)
	{
		String url = intent.getDataString();
		if (null != url)
		{
			return url.startsWith("evothings:");
		}
		else
		{
			return false;
		}
	}

	protected void openEvothingsIntent(Intent intent)
	{
		// Get the URL string of the intent.
		String url = intent.getDataString();

		// Strip off "evothings" from the URL and replace with "http".
		url = "http" + url.substring(9);

		// Load the URL in the Cordova web view.
		this.appView.loadUrlIntoView(url);
	}

	// For Cordova 3.1+
	@Override
	protected CordovaWebViewClient makeWebViewClient(CordovaWebView webView)
	{
		// If Android version is lover than HONEYCOMB we are toast
		// (loading of local Cordova files won't work in this case).
		return (android.os.Build.VERSION.SDK_INT <
				android.os.Build.VERSION_CODES.HONEYCOMB)
			? new CordovaWebViewClient(this, webView)
			: new EvothingsWebViewClient(this, webView);
	}

	public class EvothingsWebViewClient extends IceCreamCordovaWebViewClient
	{
		// Contains the name of the active cached app, or null if no cached app is active.
		// "evocache:" URLs that don't match this name will not be allowed to load.
		private String mCachedApp;
		private Evothings mEvothings;

		public EvothingsWebViewClient(Evothings evothings, CordovaWebView view)
		{
			super(evothings, view);
			mEvothings = evothings;
		}

		@Override
		public WebResourceResponse shouldInterceptRequest(WebView view, String url)
		{
			//LOG.i("EvothingsWebViewClient", "shouldInterceptRequest "+url);
			String localURL = getCordovaLocalFileURL(url);
			if (null != localURL)
			{
				return handleCordovaURL(view, Uri.parse(localURL), url);
			}
			else if (url.startsWith("evothings:"))
			{
				// Replace the 'evothings' protocol with 'http'.
				url = "http" + url.substring(9);
			}
			// If we're running a cached app, limit access to the rest of the file system.
			else if(mCachedApp != null && url.startsWith("file:"))
			{
				if(!url.startsWith(mCachedApp)) {
					LOG.e("EvothingsWebViewClient", "evocache 404 ("+mCachedApp+", "+url+")");
					return new WebResourceResponse("text/plain", "UTF-8", null);	// Results in a 404.
				}
			}
			// TODO: maybe prevent origins that aren't file:///android_asset/www/index.html from accessing these resources?
			else if(url.startsWith("evocachemeta:"))
			{
				if(url.equals("evocachemeta:app-list.json")) {
					LOG.e("EvothingsWebViewClient", "serving app-list.json...");
					try {
						return new WebResourceResponse("text/json", "UTF-8", new ByteArrayInputStream(generateClientsAppListJson()));
					} catch(Exception e) {
						e.printStackTrace();
						// no need to do anything else here.
					}
				} else {
					LOG.e("EvothingsWebViewClient", "evocachemeta unhandled: "+url);
				}
				// TODO: add a command for removing apps.
			}

			return super.shouldInterceptRequest(view, url);
		}

		private void createAppListJson(File file)
		{
			try
			{
				FileWriter w = new FileWriter(file);
				w.write("{}");
				w.close();
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
		}

		@Override
		public boolean shouldOverrideUrlLoading(WebView view, String url)
		{
			LOG.i("EvothingsWebViewClient", "shouldOverrideUrlLoading "+url);
			String cacheRoot = mEvothings.getDir("evocache", MODE_PRIVATE).toURI().toString();
			mCachedApp = null;
			// Used by external apps to load things into Evothings Client.
			if (url.startsWith("evothings:"))
			{
				// Replace the 'evothings' protocol with 'http'.
				url = "http" + url.substring(9);
				appView.loadUrlIntoView(url);
				return true;	// we handled it.
			}
			// Load a cached app.
			else if(url.startsWith(cacheRoot))
			{
				Uri uri = Uri.parse(url);
				if(!uri.getHost().equals(uri.getAuthority()))
				{
					LOG.e("EvothingsWebViewClient", "evocache 400 ("+url+")");
					return false;
				}
				// Tell future requests to load files only from this app.
				mCachedApp = url.substring(0, url.indexOf('/', cacheRoot.length()));
				LOG.e("EvothingsWebViewClient", "mCachedApp: "+mCachedApp);
				return false;	// shouldInterceptRequest will handle it.
			}
			// Cache a new app or update a cached app.
			else if(url.startsWith("evocacheadd:"))
			{
				new EvoCacheAddThread(url).start();
				return true;	// we'll handle it.
			}
			else
			{
				return false;	// system handles it.
			}
		}

		class EvoCacheAddThread extends Thread
		{
			final String mUrl;

			EvoCacheAddThread(String url)
			{
				mUrl = url;
			}

			public void run()
			{
				try
				{
					evoCacheAdd(mUrl);
				}
				catch(Exception e)
				{
					e.printStackTrace();
					// Fatal error, let's kill the app.
					throw new Error(e);
				}
			}
		}

		void downloadCacheFile(File cacheRoot, String baseUrl, String appIndex, String url) throws Exception {
			LOG.i("EvothingsWebViewClient", "downloadCacheFile("+cacheRoot.toString()+", "+baseUrl+", "+appIndex+", "+url+")");
			// we got a file, let's download it.
			int protocolIndex = url.indexOf("://");
			if(protocolIndex != -1 || url.startsWith("//")) {
				// absolute URL. TODO: try to read it as-is?
				String msg = "evocacheadd bad manifest file ("+url+")";
				LOG.e("EvothingsWebViewClient", msg);
				throw new Exception(msg);
			}
			String fileUrl, filename;
			if(url.startsWith("/")) {
				// non-relative URL. remove the prefix slash to make it usable.
				filename = url.substring(1);
			} else {
				filename = url;
			}
			fileUrl = baseUrl + filename;
			String subPath = appIndex+"/"+filename;

			// create the directory for the file.
			File file = new File(cacheRoot, subPath);
			File parent = file.getParentFile();
			parent.mkdirs();
			if(!parent.isDirectory()) {
				String msg = "evocacheadd directory creation failed ("+url+", "+parent.toString()+")";
				LOG.e("EvothingsWebViewClient", msg);
				throw new Exception(msg);
			}

			// open the file for writing.
			FileOutputStream fos = new FileOutputStream(file);

			// open the remote file.
			InputStream fis = new URL(fileUrl).openConnection().getInputStream();

			// copy the file.
			fastCopy(fis, fos);

			fos.close();
			fis.close();
		}

		// Thanks to Pavel Repin
		// http://stackoverflow.com/questions/309424/read-convert-an-inputstream-to-a-string
		String utf8StreamToString(java.io.InputStream is) throws IOException {
			java.util.Scanner s = new java.util.Scanner(is, "UTF-8").useDelimiter("\\A");
			String str = s.hasNext() ? s.next() : "";
			is.close();
			return str;
		}

		void evoCacheAdd(String url) throws Exception {
			// Load the app list.
			JSONObject appList;
			JSONObject list = null;
			File cacheRoot = mEvothings.getDir("evocache", MODE_PRIVATE);
			File appListFile = new File(cacheRoot, "app-list.json");
			if(appListFile.exists()) {
				appList = new JSONObject(utf8StreamToString(new FileInputStream(appListFile)));
				list = appList.optJSONObject("apps");
			} else {
				appList = new JSONObject();
			}
			if(list == null)
				list = new JSONObject();

			// Load the manifest.
			String manifestUrl = "http" + url.substring("evocacheadd".length());
			URL manifestURL = new URL(manifestUrl);
			String baseUrl = manifestUrl.substring(0, manifestUrl.lastIndexOf("/")+1);
			JSONObject manifest = new JSONObject(utf8StreamToString(manifestURL.openConnection().getInputStream()));
			String appName = manifest.getString("name");
			JSONArray files = manifest.getJSONArray("files");
			String startPage = manifest.getString("startPage");
			// todo: manifest.getString("startPage")

			// Construct the app's list entry, or load it if this is a previously cached app.
			int appIndex = appList.optInt("count", 0);
			JSONObject entry = list.optJSONObject(appName);
			if(entry == null) {
				// App was not previously cached. Construct a new entry.
				entry = new JSONObject();
				appIndex++;
				entry.put("index", appIndex);

				// Update counter.
				appList.put("count", appIndex);
			} else {
				// App was previously cached. Overwrite the existing entry.
				// Reuse the cache directory.
				appIndex = entry.getInt("index");
			}

			entry.put("startPage", startPage);

			// TODO: remove all files in app's cache directory.

			// Download the app's files.
			for(int i=0; i<files.length(); i++) {
				downloadCacheFile(cacheRoot, baseUrl, Integer.toString(appIndex), files.getString(i));
			}

			// Update entry.
			list.put(appName, entry);

			// Save the app list.
			appList.put("apps", list);
			FileOutputStream fos = new FileOutputStream(appListFile);
			String appListString = appList.toString();
			LOG.i("EvothingsWebViewClient", "appListFile: "+appListFile.toString());
			LOG.i("EvothingsWebViewClient", "appListString: "+appListString);
			fos.write(appListString.getBytes("UTF-8"));
			fos.close();
			LOG.i("EvothingsWebViewClient", "wrote app-list.json.");

			// Load the original client start-page. It should display the updated app list.
			appView.loadUrlIntoView("file:///android_asset/www/index.html");
		}

		// The client's app-list.json has a different format from the native one.
		byte[] generateClientsAppListJson() throws Exception {
			// Load the app list.
			JSONObject nativeList = null;
			File cacheRoot = mEvothings.getDir("evocache", MODE_PRIVATE);
			File appListFile = new File(cacheRoot, "app-list.json");
			if(appListFile.exists()) {
				JSONObject appList = new JSONObject(utf8StreamToString(new FileInputStream(appListFile)));
				nativeList = appList.optJSONObject("apps");
			}
			if(nativeList == null)
				nativeList = new JSONObject();

			// Convert each app in the list to client format.
			JSONObject clientList = new JSONObject();
			Iterator<String> keys = nativeList.keys();
			while(keys.hasNext()) {
				String name = keys.next();
				JSONObject nativeApp = nativeList.getJSONObject(name);
				String index = nativeApp.getString("index");
				String subPath = index+"/"+nativeApp.getString("startPage");
				File file = new File(cacheRoot, subPath);
				JSONObject clientApp = new JSONObject();
				clientApp.put("url", file.toURI().toString());
				clientList.put(name, clientApp);
				//LOG.i("EvothingsWebViewClient", name+": "+clientApp.toString());
			}

			JSONObject clientAppList = new JSONObject();
			clientAppList.put("apps", clientList);
			//LOG.i("EvothingsWebViewClient", clientAppList.toString());
			return clientAppList.toString().getBytes("UTF-8");
		}

		/**
		 * Here we check for Cordova files and directories.
		 * @return If the URL names an existing Cordova asset,
		 * the local URL is returned. Otherwise null is returned.
		 */
		String getCordovaLocalFileURL(String url)
		{
			int i;

			i = url.indexOf("/cordova.js");
			if (-1 < i)
			{
				return "file:///android_asset/www" + url.substring(i);
			}

			i = url.indexOf("/cordova_plugins.js");
			if (-1 < i)
			{
				return "file:///android_asset/www" + url.substring(i);
			}

			i = url.indexOf("/plugins/");
			if (-1 < i)
			{
				return "file:///android_asset/www" + url.substring(i);
			}

			// Not a Cordova file or directory.
			return null;
		}

		WebResourceResponse handleCordovaURL(
			WebView view,
			Uri assetURI,
			String originalURL)
		{
			try
			{
				CordovaResourceApi resourceApi = appView.getResourceApi();

				String encoding = "UTF-8";
				OpenForReadResult result = resourceApi.openForRead(assetURI, true);
				return new WebResourceResponse(
					result.mimeType,
					encoding,
					result.inputStream);
			}
			catch (FileNotFoundException e)
			{
				return super.shouldInterceptRequest(view, originalURL);
			}
			catch (IOException e)
			{
				LOG.e("EvothingsWebViewClient", "Error occurred while loading a file (returning a 404).", e);
				// Results in a 404.
				return new WebResourceResponse("text/plain", "UTF-8", null);
			}
		}
	}

	private static void fastCopy(final InputStream src, final OutputStream dest) throws IOException {
		final ReadableByteChannel inputChannel = Channels.newChannel(src);
		final WritableByteChannel outputChannel = Channels.newChannel(dest);
		fastCopy2(inputChannel, outputChannel);
	}

	private static void fastCopy2(final ReadableByteChannel src, final WritableByteChannel dest) throws IOException {
		final ByteBuffer buffer = ByteBuffer.allocateDirect(16 * 1024);

		while(src.read(buffer) != -1) {
			buffer.flip();
			dest.write(buffer);
			buffer.compact();
		}

		buffer.flip();

		while(buffer.hasRemaining()) {
			dest.write(buffer);
		}
	}
}
