//
//  AIProgressDataUploader.h
//  Adium
//
//  Created by Zachary West on 2009-05-27.
//  
//  Interpreted from the source of OFPOSTRequest at http://objectiveflickr.googlecode.com/svn/trunk/Source/OFPOSTRequest.m
//

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
- (void)updateUploadPercent:(CGFloat)percent context:(id)context;
- (void)uploadCompleted:(id)context result:(NSData *)result;
- (void)uploadFailed:(id)context;
@end
