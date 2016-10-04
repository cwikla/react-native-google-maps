#import "PPTGooglePlacePicker.h"
#import "RCTEventDispatcher.h"

#import <GooglePlaces/GooglePlaces.h>
#import <GooglePlacePicker/GooglePlacePicker.h>

@implementation PPTGooglePlacePicker {
    GMSPlacePicker *_placePicker;
}

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(show:
(RCTResponseSenderBlock) callback) {
    GMSPlacePickerConfig *config = [[GMSPlacePickerConfig alloc] initWithViewport:nil];
    _placePicker = [[GMSPlacePicker alloc] initWithConfig:config];
    [_placePicker pickPlaceWithCallback:^(GMSPlace *place, NSError *error) {
        if (place) {
            NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
            if (place.name) {
                [response setObject:place.name forKey:@"name"];
            }
            if (place.placeID) {
                [response setObject:place.placeID forKey:@"placeID"];
            }
            if (place.formattedAddress) {
                [response setObject:place.formattedAddress forKey:@"formattedAddress"];
            }
            NSDictionary *coordinate = @{@"latitude" : @(place.coordinate.latitude), @"longitude" : @(place.coordinate.longitude)};
            [response setObject:coordinate forKey:@"coordinate"];
            
            [response setObject:@(place.coordinate.latitude) forKey:@"latitude"];
            [response setObject:@(place.coordinate.longitude) forKey:@"longitude"];
            if (place.viewport) {
                NSDictionary *viewport = @{@"northEast" :
                                                @{@"latitude" : @(place.viewport.northEast.latitude),
                                                  @"longitude" : @(place.viewport.northEast.longitude)
                                                  },
                                           @"southWest" :
                                               @{@"latitude" : @(place.viewport.southWest.latitude),
                                                 @"longitude" : @(place.viewport.southWest.longitude)
                                                 }
                                           };
                [response setObject:viewport forKey:@"viewport"];
                
            }
            //[response setObject:place forKey:@"place"];
            callback(@[response]);
        } else if (error) {
            callback(@[@{@"error" : error.localizedFailureReason}]);

        } else {
            callback(@[@{@"didCancel" : @YES}]);
        }
    }];

}


@end
