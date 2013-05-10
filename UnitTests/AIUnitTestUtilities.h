#define AISimplifiedAssertEqualObjects(objectToTest, objectToExpect, message) \
	STAssertEqualObjects((objectToTest), (objectToExpect), @"%s: %@: Expected %C%@%C; got %C%@%C", __PRETTY_FUNCTION__, message, /*open quote*/ 0x201C, (objectToExpect), /*close quote*/ 0x201D, /*open quote*/ 0x201C, (objectToTest), /*close quote*/ 0x201D);
