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

import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;

import java.io.IOException;
import java.io.File;

import org.apache.cordova.CordovaResourceApi.OpenForReadResult;
import org.apache.cordova.*;

public class Evothings extends CordovaActivity
{
	@Override
	public void onCreate(Bundle savedInstanceState)
	{
		super.onCreate(savedInstanceState);
		super.init();
		// Set by <content src="index.html" /> in config.xml
		super.loadUrl(Config.getStartUrl());
		//super.loadUrl("file:///android_asset/www/index.html")
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
			: new MyWebViewClient(this, webView);
	}

	public class MyWebViewClient extends IceCreamCordovaWebViewClient
	{
		public MyWebViewClient(CordovaInterface cordova, CordovaWebView view)
		{
			super(cordova, view);
		}

		public WebResourceResponse shouldInterceptRequest(WebView view, String url)
		{
			String localURL = getCordovaLocalFileURL(url);
			if (null != localURL)
			{
				return handleCordovaURL(view, localURL, url);
			}
			else
			{
				return super.shouldInterceptRequest(view, url);
			}
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
			String assetURL,
			String originalURL)
		{
			try
			{
				CordovaResourceApi resourceApi = appView.getResourceApi();
				Uri uri = Uri.parse(assetURL);

				Log.i("@@@@@", "assetURL: " + assetURL);
				Log.i("@@@@@", "uri: " + uri);

				String encoding = "UTF-8";
				OpenForReadResult result = resourceApi.openForRead(uri, true);
				return new WebResourceResponse(
					result.mimeType,
					encoding,
					result.inputStream);
			}
			catch (IOException e)
			{
				return super.shouldInterceptRequest(view, originalURL);
			}
		}
	}
}
