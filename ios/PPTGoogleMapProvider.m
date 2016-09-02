#import <Foundation/NSBundle.h>
#import <GoogleMaps/GoogleMaps.h>

#import "PPTGoogleMapProvider.h"

@implementation PPTGoogleMapProvider

/**
 * Sets the google maps API key without having to include the Google Maps iOS SDK in the main
 * React project.
 *
 * @return BOOL
 */
+ (BOOL)provideAPIKey:(NSString *)apiKey {
    return [GMSServices provideAPIKey:apiKey];
}

@end
