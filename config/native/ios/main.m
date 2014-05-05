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
//
//  main.m
//  Evothings
//
//  Created by Mikael Kindborg.
//  Copyright Evothings AB 2014. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface URLProtocolCordovaJs : NSURLProtocol
@end

static NSString* pathCordovaJs = @"/cordova.js";
static NSString* pathCordovaPluginJs = @"/cordova_plugins.js";
static NSString* pathPlugins = @"/plugins";

int main(int argc, char* argv[])
{
    @autoreleasepool {
		[NSURLProtocol registerClass:[URLProtocolCordovaJs class]];
        int retVal = UIApplicationMain(argc, argv, nil, @"AppDelegate");
        return retVal;
    }
}

static NSError* createError()
{
	NSError* error =
		[NSError
		errorWithDomain: @"/"
		code: -1
		userInfo: nil];
	return error;
}

static NSString* createMimeType(NSString* pathExtension)
{
	NSString* mimeType;
	if ([pathExtension isEqualToString: @"js"])
	{
		mimeType = @"application/javascript";
	}
	else
	{
		mimeType = @"text/html";
	}
	return mimeType;
}

@implementation URLProtocolCordovaJs

+ (BOOL)canInitWithRequest:(NSURLRequest*)theRequest
{
	return [theRequest.URL.path hasPrefix: pathCordovaJs]
		|| [theRequest.URL.path hasPrefix: pathCordovaPluginJs]
		|| [theRequest.URL.path hasPrefix: pathPlugins];
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)theRequest
{
	return theRequest;
}

- (void)startLoading
{
	NSString* path = self.request.URL.path;
	NSString* pathExtension = self.request.URL.pathExtension;
	NSString* lastPathComponent = self.request.URL.lastPathComponent;
	NSString* fileNameNoExtension = [lastPathComponent stringByDeletingPathExtension];
	NSString* mimeType = createMimeType(pathExtension);

	NSString* directory = [NSString
		stringWithFormat: @"/www%@/",
		[path stringByDeletingLastPathComponent]];

	NSString* filePath = [[NSBundle mainBundle]
		pathForResource: fileNameNoExtension
		ofType: pathExtension
		inDirectory: directory];

	BOOL success = FALSE;

	if (nil != filePath)
	{
		NSData* data = [NSData dataWithContentsOfFile: filePath];
		if (nil != filePath)
		{
			NSURLResponse* response = [[NSURLResponse alloc]
			   initWithURL: self.request.URL
			   MIMEType: mimeType
			   expectedContentLength: -1
			   textEncodingName: nil];
			[[self client]
				URLProtocol: self
				didReceiveResponse: response
				cacheStoragePolicy: NSURLCacheStorageNotAllowed];
			[[self client] URLProtocol: self didLoadData: data];
			[[self client] URLProtocolDidFinishLoading: self];
			success = TRUE;
		}
	}

	if (!success)
	{
		[[self client]
			URLProtocol: self
			didFailWithError: createError()];
	}
}

- (void)stopLoading
{
	// NSLog(@"request cancelled. stop loading the response, if possible");
}

@end
