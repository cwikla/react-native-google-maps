#import <Foundation/NSObject.h>

@interface PPTGoogleMapProvider : NSObject

/**
 * Sets the google maps API key
 * @return BOOL
 */
+ (BOOL)provideAPIKey:(NSString *)apiKey;

@end
