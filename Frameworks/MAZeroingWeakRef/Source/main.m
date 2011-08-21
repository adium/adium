//
//  main.m
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import <objc/runtime.h>

#import "MANotificationCenterAdditions.h"
#import "MAZeroingWeakProxy.h"
#import "MAZeroingWeakRef.h"
#import "MAWeakArray.h"
#import "MAWeakDictionary.h"


@interface NotificationReceiver : NSObject
{
    int *_noteCounter;
}

- (id)initWithCounter: (int *)counter;

@end

@implementation NotificationReceiver

- (id)initWithCounter: (int *)counter
{
    _noteCounter = counter;
    return self;
}

- (void)gotNote: (NSNotification *)note
{
    (*_noteCounter)++;
}

@end

@interface KVOTargetSuperclass : NSObject {} @end
@implementation KVOTargetSuperclass @end

@interface KVOTarget : KVOTargetSuperclass {} @end
@implementation KVOTarget

- (void)setKey: (id)newValue
{
}

- (id)key
{
    return nil;
}

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context
{
}

@end

static void WithPool(void (^block)(void))
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    block();
    [pool release];
}

static int gFailureCount;

void Test(void (*func)(void), const char *name)
{
    WithPool(^{
        int failureCount = gFailureCount;
        NSLog(@"Testing %s", name);
        func();
        NSLog(@"%s: %s", name, failureCount == gFailureCount ? "SUCCESS" : "FAILED");
    });
}

BOOL TestException(void (^block)(void))
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        block();
        return NO;
    }
    @catch (NSException * e) {        
        return YES;
    } @finally {
      [pool drain];
    }
}

#define TEST(func) Test(func, #func)

#define TEST_EXCEPTION(block) do { \
  if(!TestException(block)) { \
    gFailureCount++; \
    NSLog(@"%s:%d: assertion failed: exception was not thrown", __func__, __LINE__); \
  } \
} while(0)

#define TEST_ASSERT(cond, ...) do { \
    if(!(cond)) { \
        gFailureCount++; \
        NSString *message = [NSString stringWithFormat: @"" __VA_ARGS__]; \
        NSLog(@"%s:%d: assertion failed: %s %@", __func__, __LINE__, #cond, message); \
    } \
} while(0)

static BOOL WaitForNil(id (^block)(void))
{
    NSProcessInfo *pi = [NSProcessInfo processInfo];
    
    NSTimeInterval start = [pi systemUptime];
    __block BOOL found;
    do
    {
        WithPool(^{
            found = block() != nil;
        });
    } while(found && [pi systemUptime] - start < 10);
    
    return !found;
}

static BOOL NilTarget(MAZeroingWeakRef *ref)
{
    return WaitForNil(^{ return [ref target]; });
}

static void TestBasic(void)
{
    NSObject *obj = [[NSObject alloc] init];
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    WithPool(^{
        TEST_ASSERT([ref target]);
        [obj release];
    });
    TEST_ASSERT(NilTarget(ref), @"ref target still live after object destroyed: %@", ref);
    [ref release];
}

static void TestRefDestroyedFirst(void)
{
    NSObject *obj = [[NSObject alloc] init];
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    WithPool(^{
        TEST_ASSERT([ref target]);
        [ref release];
    });
    [obj release];
}

static void TestDoubleRef(void)
{
    NSObject *obj = [[NSObject alloc] init];
    MAZeroingWeakRef *ref1 = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    MAZeroingWeakRef *ref2 = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    WithPool(^{
        TEST_ASSERT([ref1 target]);
        TEST_ASSERT([ref2 target]);
        [obj release];
    });
    TEST_ASSERT(NilTarget(ref1), @"ref target still live after object destroyed: %@", ref1);
    TEST_ASSERT(NilTarget(ref2), @"ref target still live after object destroyed: %@", ref2);
    [ref1 release];
    [ref2 release];
}

static void TestRefToRef(void)
{
    NSObject *obj = [[NSObject alloc] init];
    MAZeroingWeakRef *ref1 = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    MAZeroingWeakRef *ref2 = [[MAZeroingWeakRef alloc] initWithTarget: ref1];
    WithPool(^{
        TEST_ASSERT([ref1 target]);
        TEST_ASSERT([ref2 target]);
        [obj release];
    });
    WithPool(^{
        TEST_ASSERT(NilTarget(ref1), @"ref target still live after object destroyed: %@", ref1);
        TEST_ASSERT([ref2 target], @"ref target dead even though target ref still alive: %@", ref2);
        [ref1 release];
    });
    TEST_ASSERT(NilTarget(ref2), @"ref target still live after object destroyed: %@", ref2);
    [ref2 release];
}

static void TestNSArrayTarget(void)
{
    if(![MAZeroingWeakRef canRefCoreFoundationObjects])
    {
        NSLog(@"MAZeroingWeakRef can't reference CF objects, not testing them");
        return;
    }
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: array];
    WithPool(^{
        TEST_ASSERT([ref target]);
        [array release];
    });
    TEST_ASSERT(NilTarget(ref), @"ref target still live after object destroyed: %@", ref);
    [ref release];
}

static void TestNSStringTarget(void)
{
    if(![MAZeroingWeakRef canRefCoreFoundationObjects])
    {
        NSLog(@"MAZeroingWeakRef can't reference CF objects, not testing them");
        return;
    }
    
    NSString *str = [[NSMutableString alloc] initWithString: @"Test String"];
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: str];
    WithPool(^{
        TEST_ASSERT([ref target]);
        [str release];
    });
    [ref release];
}

static void TestNSConstantTarget(void)
{
    if ([MAZeroingWeakRef canRefCoreFoundationObjects]) {
      NSLog(@"MAZeroingWeakRef can reference CF objects, not testing constant object");
      return;
    }
    
    NSString *str = @"Constant String";
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: str];
    WithPool(^{
      TEST_ASSERT([ref target]);
      [str release];
    });
    [ref release];  

    TEST_EXCEPTION(^{
      NSString *str = [[NSMutableString alloc] initWithString: @"Not Constant String"];
      MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: str];
      [ref release];
    });
}

static void TestCleanup(void)
{
    __block BOOL cleanedUp = NO;
    NSObject *obj = [[NSObject alloc] init];
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    [ref setCleanupBlock: ^(id target) { cleanedUp = YES; }];
    [obj release];
    TEST_ASSERT(cleanedUp);
    [ref release];
}

static void TestCFCleanup(void)
{
    if(![MAZeroingWeakRef canRefCoreFoundationObjects])
    {
        NSLog(@"MAZeroingWeakRef can't reference CF objects, not testing them");
        return;
    }
    
    __block volatile BOOL cleanedUp = NO;
    NSObject *obj = [[NSMutableString alloc] init];
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    [ref setCleanupBlock: ^(id target) { cleanedUp = YES; }];
    [obj release];
    TEST_ASSERT(WaitForNil(^{ return (id)!cleanedUp; })
);
    [ref release];
}

static void TestNotification(void)
{
    int notificationCounter = 0;
    NotificationReceiver *receiver = [[NotificationReceiver alloc] initWithCounter: &notificationCounter];
    [[NSNotificationCenter defaultCenter] addWeakObserver: receiver selector: @selector(gotNote:) name: @"name" object: @"object"];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"name" object: @"object"];
    TEST_ASSERT(notificationCounter == 1);
    [receiver release];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"name" object: @"object"];
    TEST_ASSERT(notificationCounter == 1);
}

static void TestWeakArray(void)
{
    if(![MAZeroingWeakRef canRefCoreFoundationObjects])
    {
        NSLog(@"MAZeroingWeakRef can't reference CF objects, not testing them");
        return;
    }
    
    NSString *str1 = [[NSMutableString alloc] initWithString: @"Test String 1"];
    NSString *str2 = [[NSMutableString alloc] initWithString: @"Test String 2"];
    NSString *str3 = [[NSMutableString alloc] initWithString: @"Test String 3"];
    
    MAWeakArray *array = [[MAWeakArray alloc] init];
    [array addObject: str1];
    [array addObject: str2];
    [array addObject: str3];
    
    [str2 release];
    
    WithPool(^{
        TEST_ASSERT([array objectAtIndex: 0]);
        TEST_ASSERT(WaitForNil(^{ return [array objectAtIndex: 1]; }));
        TEST_ASSERT([array objectAtIndex: 2]);
    });
    
    [str1 release];
    [str3 release];
    
    TEST_ASSERT(WaitForNil(^{ return [array objectAtIndex: 0]; }));
    TEST_ASSERT(WaitForNil(^{ return [array objectAtIndex: 1]; }));
    TEST_ASSERT(WaitForNil(^{ return [array objectAtIndex: 2]; }));
    [array release];
}

static void TestWeakDictionary(void)
{
    if(![MAZeroingWeakRef canRefCoreFoundationObjects])
    {
        NSLog(@"MAZeroingWeakRef can't reference CF objects, not testing them");
        return;
    }
    
    NSString *str1 = [[NSMutableString alloc] initWithString: @"Test String 1"];
    NSString *str2 = [[NSMutableString alloc] initWithString: @"Test String 2"];
    NSString *str3 = [[NSMutableString alloc] initWithString: @"Test String 3"];
    
    MAWeakDictionary *dict = [[MAWeakDictionary alloc] init];
    [dict setObject: str1 forKey: @"str1"];
    [dict setObject: str2 forKey: @"str2"];
    [dict setObject: str3 forKey: @"str3"];
    
    [str2 release];
    
    WithPool(^{
        TEST_ASSERT([dict objectForKey: @"str1"]);
        TEST_ASSERT([dict objectForKey: @"str2"] == nil);
        TEST_ASSERT([dict objectForKey: @"str3"]);
    });
    
    [str1 release];
    [str3 release];
    
    TEST_ASSERT([dict objectForKey: @"str1"] == nil);
    TEST_ASSERT([dict objectForKey: @"str2"] == nil);
    TEST_ASSERT([dict objectForKey: @"str3"] == nil);
    [dict release];
}

static void TestWeakProxy(void)
{
    if(![MAZeroingWeakRef canRefCoreFoundationObjects])
    {
        NSLog(@"MAZeroingWeakRef can't reference CF objects, not testing them");
        return;
    }
    
    NSMutableString *str = [[NSMutableString alloc] init];
    NSMutableString *proxy = [[MAZeroingWeakProxy alloc] initWithTarget: str];
    
    WithPool(^{
        TEST_ASSERT([proxy isEqual: @""]);
        [proxy appendString: @"Hello, world!"];
        TEST_ASSERT([proxy isEqual: @"Hello, world!"]);
        TEST_ASSERT([proxy length] == [@"Hello, world!" length]);
        [proxy deleteCharactersInRange: NSMakeRange(0, 7)];
        TEST_ASSERT([proxy isEqual: @"world!"]);
    });
    
    [str release];
    
    TEST_ASSERT([proxy length] == 0);
    TEST_ASSERT([(id)proxy zeroingProxyTarget] == nil);
    [proxy release];
}

static void TestCleanupBlockReleasingZWR(void)
{
    NSObject *obj = [[NSObject alloc] init];
    WithPool(^{
        __block MAZeroingWeakRef *ref1 = [[MAZeroingWeakRef alloc] initWithTarget: obj];
        __block MAZeroingWeakRef *ref2 = [[MAZeroingWeakRef alloc] initWithTarget: obj];
        __block MAZeroingWeakRef *ref3 = [[MAZeroingWeakRef alloc] initWithTarget: obj];
        
        id cleanupBlock = ^{
            [ref1 release];
            ref1 = nil;
            [ref2 release];
            ref2 = nil;
            [ref3 release];
            ref3 = nil;
        };
        
        [ref1 setCleanupBlock: cleanupBlock];
        [ref2 setCleanupBlock: cleanupBlock];
        [ref3 setCleanupBlock: cleanupBlock];
    });
    [obj release];
}

static void TestAccidentalResurrectionInCleanupBlock(void)
{
    NSObject *obj = [[NSObject alloc] init];
    WithPool(^{
        __block MAZeroingWeakRef *ref1 = [[MAZeroingWeakRef alloc] initWithTarget: obj];
        __block MAZeroingWeakRef *ref2 = [[MAZeroingWeakRef alloc] initWithTarget: obj];
        
        id cleanupBlock = ^{
            [ref1 target];
            [ref2 target];
        };
        
        [ref1 setCleanupBlock: cleanupBlock];
        [ref2 setCleanupBlock: cleanupBlock];
        
        [obj release];
        [ref1 release];
        [ref2 release];
    });
}

static void TestKVOTarget(void)
{
    KVOTarget *target = [[KVOTarget alloc] init];
    void (^describe)(void) = ^{
        return;
        
        Class nsClass = [target class];
        NSString *nsName = [nsClass description];
        Class objcClass = object_getClass(target);
        const char *objcName = class_getName(objcClass);
        
        NSLog(@"%@, %s %@ %p %p", target, objcName, nsName, objcClass, nsClass);
    };
    
    describe();
    
    [target addObserver: target forKeyPath: @"key" options: 0 context: NULL];
    describe();
    
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: target];
    describe();
    
    [target setKey: @"value"];
    describe();
    
    [ref release];
    describe();
}

static void TestClassForCoder(void)
{
    NSObject *obj = [[NSObject alloc] init];
    TEST_ASSERT([obj classForCoder] == [NSObject class]);
    [[[MAZeroingWeakRef alloc] initWithTarget: obj] autorelease];
    TEST_ASSERT([obj classForCoder] == [NSObject class]);
}

static void TestKVOReleaseNoCrash(void)
{
	KVOTarget *target = [[KVOTarget alloc] init];
    
	MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: target];
    
	[target addObserver: target forKeyPath: @"key" options: 0 context: NULL];
    
	[target setKey: @"value"];
    
    // destroying target without removing the observer tosses a warning to the console
    // but it's necessary in order to test this failure mode
	[target release];	
	[ref target];
    
	[ref release];
}

static void TestKVOReleaseCrash(void)
{
	KVOTarget *target = [[KVOTarget alloc] init];
    
	[target addObserver: target forKeyPath: @"key" options: 0 context: NULL];
    
	MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: target];
    
	[target setKey: @"value"];
    
	[target release];	
	[ref target];
    
	[ref release];
}

int main(int argc, const char * argv[])
{
    WithPool(^{
        TEST(TestBasic);
        TEST(TestRefDestroyedFirst);
        TEST(TestDoubleRef);
        TEST(TestRefToRef);
        TEST(TestNSArrayTarget);
        TEST(TestNSStringTarget);
        TEST(TestNSConstantTarget);
        TEST(TestCleanup);
        TEST(TestCFCleanup);
        TEST(TestNotification);
        TEST(TestWeakArray);
        TEST(TestWeakDictionary);
        TEST(TestWeakProxy);
        TEST(TestCleanupBlockReleasingZWR);
        TEST(TestAccidentalResurrectionInCleanupBlock);
        TEST(TestKVOTarget);
        TEST(TestClassForCoder);
        TEST(TestKVOReleaseNoCrash);
        TEST(TestKVOReleaseCrash);
        
        NSString *message;
        if(gFailureCount)
            message = [NSString stringWithFormat: @"FAILED: %d total assertion failure%s", gFailureCount, gFailureCount > 1 ? "s" : ""];
        else
            message = @"SUCCESS";
        NSLog(@"Tests complete: %@", message);
    });
    return 0;
}

