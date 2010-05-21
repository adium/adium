/*
 *  AIJavaControllerProtocol.h
 *  Adium
 *
 *  Created by Andreas Monitzer on 2006-08-17.
 *
 */

#import <Adium/AIControllerProtocol.h>

@interface JavaField : NSObject {
}

- (id)get:(id)obj; // param is the instance, pass nil if it's a static field

@end

@protocol JavaObject <NSObject>
+ (BOOL)equals:(id)obj;
+ (id)newInstance;
+ (NSString*)toString;
+ (BOOL)isInstace:(id)obj;
+ (JavaField *)getField:(NSString*)name;
+ (NSString *)getProperty:(NSString *)propertyName;

// these are Java Bridge methods!
+ (id)alloc;
+ (id)newWithSignature:(NSString*)sig, ...;
@end

@interface JavaObject : NSObject <JavaObject> {
	
}
@end

/*!
 * @brief A JavaClassLoader loads classes from jars; it is initialized for one or more jars.
 *
 * It is actually a java object; loadClass is therefore never implemented in Objective C code.
 */
@interface JavaClassLoader : NSObject {
}

// param format: http://java.sun.com/j2se/1.5.0/docs/api/java/lang/ClassLoader.html#name
- (Class <JavaObject>)loadClass:(NSString *)classname;
@end

/*!
 * @brief The JavaController itself
 */
@protocol AIJavaController <AIController>
- (JavaClassLoader *)classLoaderWithJARs:(NSArray *)jararray;
- (JavaClassLoader *)classLoaderWithJARs:(NSArray *)jararray parentClassLoader:(JavaClassLoader *)parent;
@end
