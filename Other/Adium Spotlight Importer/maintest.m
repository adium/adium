#import "AdiumSpotlightImporter.h"

int main(int argc, const char *argv[])
{
	NSLog(@"%@", CopyTextContentForFile(NULL, CFStringCreateWithCString(NULL,argv[1], kCFStringEncodingUTF8)));
}
