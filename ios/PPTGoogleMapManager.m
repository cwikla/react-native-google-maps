#import "PPTGoogleMapManager.h"

#import "RCTBridge.h"
#import "RCTUIManager.h"
#import "RCTEventDispatcher.h"
#import "PPTGoogleMap.h"
#import "UIView+React.h"


#define COORDTODICT(a) @{@"latitude" : @((a).latitude), @"longitude" : @((a).longitude)}

@implementation PPTGoogleMapManager

RCT_EXPORT_MODULE()

/**
 * Create a new React Native Google Map view and set the view delegate to this class.
 *
 * @return GoogleMap
 */
- (UIView *)view
{
    PPTGoogleMap *map = [[PPTGoogleMap alloc] init];
    
    map.delegate = self;
    
    return map;
}

RCT_EXPORT_VIEW_PROPERTY(cameraPosition, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(showsUserLocation, BOOL)
RCT_EXPORT_VIEW_PROPERTY(scrollGestures, BOOL)
RCT_EXPORT_VIEW_PROPERTY(zoomGestures, BOOL)
RCT_EXPORT_VIEW_PROPERTY(tiltGestures, BOOL)
RCT_EXPORT_VIEW_PROPERTY(rotateGestures, BOOL)
RCT_EXPORT_VIEW_PROPERTY(consumesGesturesInView, BOOL)
RCT_EXPORT_VIEW_PROPERTY(compassButton, BOOL)
RCT_EXPORT_VIEW_PROPERTY(myLocationButton, BOOL)
RCT_EXPORT_VIEW_PROPERTY(indoorPicker, BOOL)
RCT_EXPORT_VIEW_PROPERTY(allowScrollGesturesDuringRotateOrZoom, BOOL)
RCT_EXPORT_VIEW_PROPERTY(markers, NSDictionaryArray)
RCT_EXPORT_VIEW_PROPERTY(circles, NSDictionaryArray)
RCT_EXPORT_VIEW_PROPERTY(polygons, NSDictionaryArray)

#pragma mark GMSMapViewDelegate

/**
 * Called before the camera on the map changes, either due to a gesture, animation (e.g., by a user tapping on the "My Location"
 * button) or by being updated explicitly via the camera or a zero-length animation on layer.
 *
 * @return void
 */
- (void)mapView:(PPTGoogleMap *)mapView willMove:(BOOL)gesture
{
    NSString *type = @"animation";
    
    if (gesture) {
        type = @"gesture";
    }
    
    NSDictionary *event = @{@"target": mapView.reactTag, @"event": @"willMove", @"type": type};
    
    [self.bridge.eventDispatcher sendInputEventWithName:@"topChange" body:event];
}

/**
 * Called repeatedly during any animations or gestures on the map (or once, if the camera is explicitly set).
 * This may not be called for all intermediate camera positions. It is always called for the final position of an animation or
 * gesture.
 *
 * @return void
 */
- (void)mapView:(PPTGoogleMap *)mapView didChangeCameraPosition:(GMSCameraPosition *)position
{
    
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithRegion:mapView.projection.visibleRegion];
    
    NSDictionary *dictBounds = @{@"northEast" : COORDTODICT(bounds.northEast),
                             @"southWest" : COORDTODICT(bounds.southWest)};

    NSDictionary *event = @{
                            @"target": mapView.reactTag,
                            @"event": @"didChangeCameraPosition",
                            @"data": @{
                                    @"coord" : COORDTODICT(position.target),
                                    @"bounds" : dictBounds,
                                    @"zoom": @(position.zoom)
                                    }
                            };
    
    [self.bridge.eventDispatcher sendInputEventWithName:@"topChange" body:event];
}

/**
 * Called when the map becomes idle, after any outstanding gestures or animations have completed (or after the camera has
 * been explicitly set).
 *
 * @return void
 */
- (void)mapView:(PPTGoogleMap *)mapView idleAtCameraPosition:(GMSCameraPosition *)position
{
    
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithRegion:mapView.projection.visibleRegion];
    
    NSDictionary *dictBounds = @{@"northEast" : COORDTODICT(bounds.northEast),
                                 @"southWest" : COORDTODICT(bounds.southWest)};
    

    NSDictionary *event = @{
                            @"target": mapView.reactTag,
                            @"event": @"idleAtCameraPosition",
                            @"data": @{
                                    @"bounds" : dictBounds,
                                    @"coord" : COORDTODICT(position.target),
                                    @"zoom": @(position.zoom)
                                    }
                            };
    
    [self.bridge.eventDispatcher sendInputEventWithName:@"topChange" body:event];
}

/**
 * Called after a tap gesture at a particular coordinate, but only if a marker was not tapped.
 * This is called before deselecting any currently selected marker (the implicit action for tapping on the map).
 *
 * @return void
 */
- (void)mapView:(PPTGoogleMap *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSDictionary *event = @{
                            @"target": mapView.reactTag,
                            @"event": @"didTapAtCoordinate",
                            @"data": @{
                                    @"coord" : COORDTODICT(coordinate)
                                    }
                            };
    
    [self.bridge.eventDispatcher sendInputEventWithName:@"topChange" body:event];
}

/**
 * Called after a long-press gesture at a particular coordinate.
 *
 * @return void
 */
- (void)mapView:(PPTGoogleMap *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSDictionary *event = @{
                            @"target": mapView.reactTag,
                            @"event": @"didLongPressAtCoordinate",
                            @"data": @{
                                    @"coord" : COORDTODICT(coordinate)
                                    }
                            };
    
    [self.bridge.eventDispatcher sendInputEventWithName:@"topChange" body:event];
}


/**
 * Called after a marker has been tapped.
 *
 * @return BOOL
 */
- (BOOL)mapView:(PPTGoogleMap *)mapView didTapMarker:(PPTMarker *)marker
{
    CLLocationCoordinate2D thing = marker.position;
    
    NSDictionary *event = @{
                            @"target": mapView.reactTag,
                            @"event": @"didTapMarker",
                            @"key": marker.key ? marker.key : [NSNull null],
                            @"data": @{
                                    @"coord" : COORDTODICT(marker.position)
                                    }
                            };
    [self.bridge.eventDispatcher sendInputEventWithName:@"topChange" body:event];
    
    return NO;
}

/**
 * Called after an overlay has been tapped.
 *
 * @return void
 */
- (void)mapView:(PPTGoogleMap *)mapView didTapOverlay:(GMSOverlay *)overlay
{
    NSString *key = [NSNull null];
    NSString *eventName = nil;
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    event[@"target"] = mapView.reactTag;
    
    if ([overlay isKindOfClass:[PPTPolygon class]]) {
        key = ((PPTPolygon *)overlay).key;
        eventName = @"didTapPolygon";
    }
    else if ([overlay isKindOfClass:[PPTCircle class]]) {
        key = ((PPTCircle *)overlay).key;
        eventName = @"didTapCircle";
    }
    else if ([overlay isKindOfClass:[PPTMarker class]]) {
        key = ((PPTMarker *)overlay).key;
        eventName = @"didTapMarker";
    }
    
    event[@"key"] = key;
    event[@"event"] = eventName;
    
    [self.bridge.eventDispatcher sendInputEventWithName:@"topChange" body:event];
}

/**
 * Called when dragging has been initiated on a marker.
 *
 * @return void
 */
- (void)mapView:(PPTGoogleMap *)mapView didBeginDraggingMarker:(PPTMarker *)marker
{
    NSDictionary *event = @{
                            @"target": mapView.reactTag,
                            @"event": @"didTapMarker",
                            @"key": marker.key ? marker.key : [NSNull null],
                            @"data": @{
                                    @"coord" : COORDTODICT(marker.position)
                                    }
                            };
    
    [self.bridge.eventDispatcher sendInputEventWithName:@"topChange" body:event];
}

/**
 * Called after dragging of a marker ended.
 *
 * @return void
 */
- (void)mapView:(PPTGoogleMap *)mapView didEndDraggingMarker:(PPTMarker *)marker
{
    NSDictionary *event = @{
                            @"target": mapView.reactTag,
                            @"event": @"didTapMarker",
                            @"key": marker.key ? marker.key : [NSNull null],
                            @"data": @{
                                    @"coord" : COORDTODICT(marker.position)
                                    }
                            };
    
    [self.bridge.eventDispatcher sendInputEventWithName:@"topChange" body:event];
}

/**
 * Called while a marker is dragged.
 *
 * @return void
 */
- (void)mapView:(PPTGoogleMap *)mapView didDragMarker:(PPTMarker *)marker
{
    NSDictionary *event = @{
                            @"target": mapView.reactTag,
                            @"event": @"didTapMarker",
                            @"key": marker.key ? marker.key : [NSNull null],
                            @"data": @{
                                    @"coord": COORDTODICT(marker.position)
                                    }
                            };
    
    [self.bridge.eventDispatcher sendInputEventWithName:@"topChange" body:event];
}

/**
 * Called when the My Location button is tapped. Returns YES if the listener has consumed the event (i.e., the default behavior
 * should not occur), NO otherwise (i.e., the default behavior should occur). The default behavior is for the camera to move
 * such that it is centered on the user location.
 *
 * @return BOOL
 */
- (BOOL)didTapMyLocationButtonForMapView:(PPTGoogleMap *)mapView
{
    CLLocationCoordinate2D location = mapView.myLocation.coordinate;
    
    NSDictionary *event = @{@"target": mapView.reactTag,
                            @"event": @"didTapMyLocationButtonForMapView",
                            @"data": @{
                                    @"coord": COORDTODICT(location)
                                    }
                            };
    
    
    [self.bridge.eventDispatcher sendInputEventWithName:@"topChange" body:event];
    
    return NO;
}

- (void)didDrag:(PPTGoogleMap *)mapView {
    NSDictionary *event = @{@"target": mapView.reactTag,
                            @"event": @"didDrag",
                            };
    
    
    [self.bridge.eventDispatcher sendInputEventWithName:@"topChange" body:event];

}


RCT_EXPORT_METHOD(bounds:(NSNumber *)reactTag callback:(RCTResponseSenderBlock)callback)
{
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary *viewRegistry) {
        PPTGoogleMap *view = viewRegistry[reactTag];
        if ([view isKindOfClass:[GMSMapView class]]) {
            GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithRegion:view.projection.visibleRegion];
            
            callback(@[@{@"northEast" : COORDTODICT(bounds.northEast),
                         @"southWest" : COORDTODICT(bounds.southWest)}]);
        }
    }];
}



@end
