//
//  AIProgressDataUploader.h
//  Adium
//
//  Created by Zachary West on 2009-05-27.
//  
//  Thoroughly modified from the source of OFPOSTRequest at
//  http://objectiveflickr.googlecode.com/svn/trunk/Source/OFPOSTRequest.m
//
// Copyright (c) 2004-2006 Lukhnos D. Liu (lukhnos {at} gmail.com)
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Neither the name of ObjectiveFlickr nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

@protocol AIProgressDataUploaderDelegate;

@interface AIProgressDataUploader : NSObject {
	NSData									*uploadData;
	NSURL									*url;
	NSDictionary							*headers;
	id <AIProgressDataUploaderDelegate>		delegate;
	id										context;
	
	CFReadStreamRef							stream;
	NSMutableData							*returnedData;
	
	NSInteger								totalSize;
	NSInteger								bytesSent;
	
	NSTimer									*timeoutTimer;
	NSTimer									*periodicTimer;
}

+ (id)dataUploaderWithData:(NSData *)uploadData
					   URL:(NSURL *)url
				   headers:(NSDictionary *)headers
				  delegate:(id <AIProgressDataUploaderDelegate>)delegate
				   context:(id)context;

- (void)upload;
- (void)cancel;

@end

@protocol AIProgressDataUploaderDelegate
- (void)updateUploadProgress:(NSUInteger)uploaded total:(NSUInteger)total context:(id)context;
- (void)uploadCompleted:(id)context result:(NSData *)result;
- (void)uploadFailed:(id)context;
@end
