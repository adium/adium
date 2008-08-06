//
//  TestWiredString.h
//  Adium
//
//  Created by Peter Hosey on 2008-07-03.
//  Copyright 2008 Peter Hosey. All rights reserved.
//

@interface TestWiredString : SenTestCase
{}

#pragma mark Testing autoreleased factories

//+string
- (void) testEmptyAutoreleasedString;
//+stringWithUTF8String:
- (void) testAutoreleasedStringWithUTF8String;
- (void) testAutoreleasedStringWithEmptyUTF8String;
- (void) testAutoreleasedStringWithNULLUTF8String;
//+stringWithString:
- (void) testAutoreleasedStringWithString;
- (void) testAutoreleasedStringWithEmptyString;
- (void) testAutoreleasedStringWithNoString;

#pragma mark Testing non-autoreleased factories

//-init
- (void) testInitEmptyString;
//initWithCharacters:length:
- (void) testInitWithUTF16Characters;
//initWithCharacters:length:0
- (void) testInitWithNoUTF16Characters;
- (void) testInitWithNULLAndNoUTF16Characters;
- (void) testInitWithNULLUTF16Characters;
//initWithData:encoding:
- (void) testInitWithDataAndASCIIEncoding;
- (void) testInitWithDataAndUTF8Encoding;
- (void) testInitWithDataAndUTF16Encoding;
- (void) testInitWithNoDataAndASCIIEncoding;
- (void) testInitWithNoDataAndUTF8Encoding;
- (void) testInitWithNoDataAndUTF16Encoding;
//initWithBytes:length:encoding:
- (void) testInitWithBytesAndLengthAndASCIIEncoding;
- (void) testInitWithBytesAndLengthAndUTF8Encoding;
- (void) testInitWithBytesAndLengthAndUTF16Encoding;
- (void) testInitWithBytesAndZeroLengthAndASCIIEncoding;
- (void) testInitWithBytesAndZeroLengthAndUTF8Encoding;
- (void) testInitWithBytesAndZeroLengthAndUTF16Encoding;
- (void) testInitWithNULLBytesAndZeroLengthAndASCIIEncoding;
- (void) testInitWithNULLBytesAndZeroLengthAndUTF8Encoding;
- (void) testInitWithNULLBytesAndZeroLengthAndUTF16Encoding;
//These should raise.
- (void) testInitWithNULLBytesAndLengthAndASCIIEncoding;
- (void) testInitWithNULLBytesAndLengthAndUTF8Encoding;
- (void) testInitWithNULLBytesAndLengthAndUTF16Encoding;
//-initWithUTF8String:
- (void) testInitWithUTF8String;
- (void) testInitWithEmptyUTF8String;
- (void) testInitWithNULLUTF8String;
//-initWithString:
- (void) testInitWithString;
- (void) testInitWithEmptyString;
- (void) testInitWithNoString;

#pragma mark Testing character retrieval

//-length
- (void) testLength;
- (void) testEmptyLength;

//-getCharacters:
- (void) testGetCharacters;
- (void) testGetCharactersToNULL;

//-getCharacters:range:
- (void) testGetCharactersInRange;
- (void) testGetCharactersInEmptyRange;
- (void) testGetCharactersInRangeToNULL;
- (void) testGetCharactersInEmptyRangeToNULL;

//-dataUsingEncoding:allowLossyConversion:nulTerminate:
- (void) testDataUsingASCIIEncodingFromASCIIWithoutLossyConversionWithoutNulTermination;
- (void) testDataUsingASCIIEncodingFromASCIIWithoutLossyConversionWithNulTermination;
- (void) testDataUsingASCIIEncodingFromASCIIWithLossyConversionWithoutNulTermination;
- (void) testDataUsingASCIIEncodingFromASCIIWithLossyConversionWithNulTermination;
- (void) testDataUsingUTF8EncodingFromASCIIWithoutLossyConversionWithoutNulTermination;
- (void) testDataUsingUTF8EncodingFromASCIIWithoutLossyConversionWithNulTermination;
- (void) testDataUsingUTF8EncodingFromASCIIWithLossyConversionWithoutNulTermination;
- (void) testDataUsingUTF8EncodingFromASCIIWithLossyConversionWithNulTermination;
- (void) testDataUsingUTF16EncodingFromASCIIWithoutLossyConversionWithoutNulTermination;
- (void) testDataUsingUTF16EncodingFromASCIIWithoutLossyConversionWithNulTermination;
- (void) testDataUsingUTF16EncodingFromASCIIWithLossyConversionWithoutNulTermination;
- (void) testDataUsingUTF16EncodingFromASCIIWithLossyConversionWithNulTermination;
- (void) testDataUsingASCIIEncodingFromUTF8WithoutLossyConversionWithoutNulTermination;
- (void) testDataUsingASCIIEncodingFromUTF8WithoutLossyConversionWithNulTermination;
- (void) testDataUsingASCIIEncodingFromUTF8WithLossyConversionWithoutNulTermination;
- (void) testDataUsingASCIIEncodingFromUTF8WithLossyConversionWithNulTermination;
- (void) testDataUsingUTF8EncodingFromUTF8WithoutLossyConversionWithoutNulTermination;
- (void) testDataUsingUTF8EncodingFromUTF8WithoutLossyConversionWithNulTermination;
- (void) testDataUsingUTF8EncodingFromUTF8WithLossyConversionWithoutNulTermination;
- (void) testDataUsingUTF8EncodingFromUTF8WithLossyConversionWithNulTermination;
- (void) testDataUsingUTF16EncodingFromUTF8WithoutLossyConversionWithoutNulTermination;
- (void) testDataUsingUTF16EncodingFromUTF8WithoutLossyConversionWithNulTermination;
- (void) testDataUsingUTF16EncodingFromUTF8WithLossyConversionWithoutNulTermination;
- (void) testDataUsingUTF16EncodingFromUTF8WithLossyConversionWithNulTermination;
- (void) testDataUsingASCIIEncodingFromUTF16WithoutLossyConversionWithoutNulTermination;
- (void) testDataUsingASCIIEncodingFromUTF16WithoutLossyConversionWithNulTermination;
- (void) testDataUsingASCIIEncodingFromUTF16WithLossyConversionWithoutNulTermination;
- (void) testDataUsingASCIIEncodingFromUTF16WithLossyConversionWithNulTermination;
- (void) testDataUsingUTF8EncodingFromUTF16WithoutLossyConversionWithoutNulTermination;
- (void) testDataUsingUTF8EncodingFromUTF16WithoutLossyConversionWithNulTermination;
- (void) testDataUsingUTF8EncodingFromUTF16WithLossyConversionWithoutNulTermination;
- (void) testDataUsingUTF8EncodingFromUTF16WithLossyConversionWithNulTermination;
- (void) testDataUsingUTF16EncodingFromUTF16WithoutLossyConversionWithoutNulTermination;
- (void) testDataUsingUTF16EncodingFromUTF16WithoutLossyConversionWithNulTermination;
- (void) testDataUsingUTF16EncodingFromUTF16WithLossyConversionWithoutNulTermination;
- (void) testDataUsingUTF16EncodingFromUTF16WithLossyConversionWithNulTermination;

//-dataUsingEncoding:allowLossyConversion:
- (void) testDataUsingASCIIEncodingFromASCIIWithoutLossyConversion;
- (void) testDataUsingASCIIEncodingFromASCIIWithLossyConversion;
- (void) testDataUsingUTF8EncodingFromASCIIWithoutLossyConversion;
- (void) testDataUsingUTF8EncodingFromASCIIWithLossyConversion;
- (void) testDataUsingUTF16EncodingFromASCIIWithoutLossyConversion;
- (void) testDataUsingUTF16EncodingFromASCIIWithLossyConversion;
- (void) testDataUsingASCIIEncodingFromUTF8WithoutLossyConversion;
- (void) testDataUsingASCIIEncodingFromUTF8WithLossyConversion;
- (void) testDataUsingUTF8EncodingFromUTF8WithoutLossyConversion;
- (void) testDataUsingUTF8EncodingFromUTF8WithLossyConversion;
- (void) testDataUsingUTF16EncodingFromUTF8WithoutLossyConversion;
- (void) testDataUsingUTF16EncodingFromUTF8WithLossyConversion;
- (void) testDataUsingASCIIEncodingFromUTF16WithoutLossyConversion;
- (void) testDataUsingASCIIEncodingFromUTF16WithLossyConversion;
- (void) testDataUsingUTF8EncodingFromUTF16WithoutLossyConversion;
- (void) testDataUsingUTF8EncodingFromUTF16WithLossyConversion;
- (void) testDataUsingUTF16EncodingFromUTF16WithoutLossyConversion;
- (void) testDataUsingUTF16EncodingFromUTF16WithLossyConversion;

//-dataUsingEncoding:
- (void) testDataUsingASCIIEncodingFromASCII;
- (void) testDataUsingUTF8EncodingFromASCII;
- (void) testDataUsingUTF16EncodingFromASCII;
- (void) testDataUsingASCIIEncodingFromUTF8;
- (void) testDataUsingUTF8EncodingFromUTF8;
- (void) testDataUsingUTF16EncodingFromUTF8;
- (void) testDataUsingASCIIEncodingFromUTF16;
- (void) testDataUsingUTF8EncodingFromUTF16;
- (void) testDataUsingUTF16EncodingFromUTF16;

//-UTF8String
- (void) testUTF8String;
- (void) testEmptyUTF8String;

#pragma mark Testing comparison

//-isEqualToString:
- (void) testIsEqualToString;
- (void) testIsNotEqualToString;

//-isEqual:
- (void) testIsEqual;
- (void) testIsNotEqual;

//-hash
- (void) testHash;
- (void) testEmptyHash;

@end
