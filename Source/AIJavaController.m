//
//  AIJavaController.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-31.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "AIJavaController.h"
#import <JavaVM/NSJavaVirtualMachine.h>

@interface JavaVector : NSObject {
}

- (void)add:(id)obj;
- (NSString*)toString;

@end

@protocol JavaCocoaAdapter
- (JavaClassLoader*)classLoader:(JavaVector*)jars :(JavaClassLoader*)parent;
@end

@implementation AIJavaController

/*!
* @brief Controller loaded
 */
- (void)controllerDidLoad
{
}

/*!
* @brief Controller will close
 */
- (void)controllerWillClose
{
}

- (JavaClassLoader *)classLoaderWithJARs:(NSArray *)jars
{
    return [self classLoaderWithJARs:jars parentClassLoader:nil];
}

/*!
 * @brief XXX
 *
 * @result a JavaClassLoader which loads classes from the indicated jars
 */
- (JavaClassLoader*)classLoaderWithJARs:(NSArray*)jars parentClassLoader:(JavaClassLoader*)parent
{
    if (!vm) {
        vm = [[NSJavaVirtualMachine alloc] initWithClassPath:[NSJavaVirtualMachine defaultClassPath]];
        //Dynamically load class file
        JavaCocoaAdapter = [vm defineClass:[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"JavaCocoaAdapter" ofType:@"class"]] withName:@"net/adium/JavaCocoaAdapter"];
        NSLog(@"JavaCocoaAdapter = %@", JavaCocoaAdapter);
    }
    
    //Convert NSArray to java.util.Vector
    JavaVector *vec = [[vm findClass:@"java.util.Vector"] newWithSignature:@"(I)",[jars count]];
    
    NSEnumerator *enumerator = [jars objectEnumerator];
    NSString	 *path;
    while ((path = [enumerator nextObject])) {
        [vec add:path];
	}

    JavaClassLoader *result = [JavaCocoaAdapter classLoader:vec :parent];
    [vec release];

    return result;
}

@end
