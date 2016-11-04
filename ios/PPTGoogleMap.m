#import "PPTGoogleMap.h"

#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTLog.h"
#import "RCTUtils.h"

#import "UIColor+HexString.h"

@implementation PPTMarker

+ (instancetype)markerWithPosition:(CLLocationCoordinate2D)position
                            andKey:key
{
    PPTMarker *marker = [[PPTMarker alloc] init];
    marker.key = key;
    marker.position = position;
    return marker;
}

@end

// http://stackoverflow.com/questions/23016992/change-gmscircle-radius-with-animation

@implementation PPTCircle
{
    CLLocationDistance _from;
    CLLocationDistance _to;
    NSTimeInterval _duration;
}

// just call this
-(void)beginRadiusAnimationFrom:(CLLocationDistance)from
                             to:(CLLocationDistance)to
                       duration:(NSTimeInterval)duration
                completeHandler:(void(^)())completeHandler {
    
    self.handler = completeHandler;
    self.begin = [NSDate date];
    _from = from;
    _to = to;
    _duration = duration;
    
    [self performSelectorOnMainThread:@selector(updateSelf) withObject:nil waitUntilDone:NO];
}

// internal update
-(void)updateSelf {
    
    NSTimeInterval i = [[NSDate date] timeIntervalSinceDate:_begin];
    if (i >= _duration) {
        CLLocationDistance tmp = _to;
        _to = _from;
        _from = tmp;
        _begin = [NSDate date];
    }
    
    CLLocationDistance d = (_to - _from) * i / _duration + _from;
    if (d < 0.1) {
        d = 0.1;
    }
    self.radius = d;
    // do it again at next run loop
    [self performSelectorOnMainThread:@selector(updateSelf) withObject:nil waitUntilDone:NO];
}


+ (instancetype)circleWithPosition:(CLLocationCoordinate2D)position
                            radius:(CLLocationDistance)radius
                            andKey:(NSString *)key
                  andAnimationTime:(NSNumber *)animationTime
{
    PPTCircle *circle = [[PPTCircle alloc] init];
    circle.position = position;
    circle.radius = radius;
    circle.key = key;
    
    if (animationTime) {
        [circle beginRadiusAnimationFrom:0.1 to:radius duration:animationTime.doubleValue completeHandler:nil];
    }
    return circle;
}
@end

@implementation PPTPolygon

+ (instancetype)polygonWithPath:(GMSPath *)path
                         andKey:(NSString *)key
{
    PPTPolygon *poly = [[PPTPolygon alloc] init];
    poly.path = path;
    poly.key = key;
    return poly;
}
@end

@implementation PPTGoogleMap {
    NSMutableDictionary *markerImages;
    NSMutableDictionary *markers;
    NSMutableDictionary *circles;
    NSMutableDictionary *polygons;
    CLLocationManager *locationManager;
}

/**
 * Init the google map view class.
 *
 * @return id
 */
- (id)init
{
    if (self = [super init]) {
        markerImages = [[NSMutableDictionary alloc] init];
        markers = [[NSMutableDictionary alloc] init];
        circles = [[NSMutableDictionary alloc] init];
        polygons = [[NSMutableDictionary alloc] init];
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.zoom = 10;
    }
    
    for (UIGestureRecognizer *gestureRecognizer in self.gestureRecognizers) {
        [gestureRecognizer addTarget:self action:@selector(recognizeMapDrag:)];
    }
    

    
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    int i = 1;
}


-(IBAction) recognizeMapDrag:(UIPanGestureRecognizer*)sender {
    
    SEL sel = @selector(didDrag:);
    
    if (self.delegate && [self.delegate respondsToSelector:sel]) {
        [self.delegate performSelector:sel withObject:self];
    }
}

- (void)dealloc {
    if (locationManager) {
        [locationManager stopUpdatingLocation];
    }
}

/**
 * Enables layout sub-views which are required to render a non-blank map.
 *
 * @return void
 */
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect mapFrame = self.frame;
    
    self.frame = CGRectZero;
    self.frame = mapFrame;
}

#pragma mark Accessors

/**
 * Sets the map camera position.
 *
 * @return void
 */
- (void)setCameraPosition:(NSDictionary *)cameraPosition
{
    if (cameraPosition[@"zoom"]) {
        self.zoom = ((NSNumber*)cameraPosition[@"zoom"]).doubleValue;
    }
    
    if (cameraPosition[@"auto"]  && ((NSNumber*)cameraPosition[@"auto"]).boolValue == true) {
        [locationManager startUpdatingLocation];
    }
    else {
        CLLocationDegrees latitude = ((NSNumber*)cameraPosition[@"latitude"]).doubleValue;
        CLLocationDegrees longitude = ((NSNumber*)cameraPosition[@"longitude"]).doubleValue;
        
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:latitude
                                                                longitude:longitude
                                                                     zoom:self.zoom];
        
        self.camera = camera;
        
        CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(latitude, longitude);
        [self animateWithCameraUpdate:[GMSCameraUpdate setTarget:coords zoom:self.zoom]];
        //        [self moveCamera:[GMSCameraUpdate setTarget:coords zoom:zoom]];
        
        
    }
}

/**
 * The delegate for the did update location event - fired when the user's location becomes available and then centers the
 * map about the their location. The location manager is then stopped so that the map position doesn't continue to be updated.
 *
 * @return void
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    CLLocation* location = [locations lastObject];
   
    [self animateWithCameraUpdate:[GMSCameraUpdate setTarget:location.coordinate zoom:self.zoom]];
    
    //[locationManager stopUpdatingLocation];
}

/**
 * Adds circles to the map.
 *
 * @return void
 */
- (void)setCircles:(NSArray *)inCircles
{
    NSMutableDictionary *found = [[NSMutableDictionary alloc] init];

    for (NSDictionary* circle in inCircles) {
        NSString *key = circle[@"key"];
        CLLocationDegrees latitude = ((NSNumber*)circle[@"latitude"]).doubleValue;
        CLLocationDegrees longitude = ((NSNumber*)circle[@"longitude"]).doubleValue;
        CLLocationDistance radius = ((NSNumber*)circle[@"radius"]).doubleValue;
        NSNumber *animationTime = circle[@"animationTime"];
        
        PPTCircle *mapCircle = circles[key];
        if (!mapCircle) {
            mapCircle = [PPTCircle circleWithPosition:CLLocationCoordinate2DMake(latitude, longitude) radius:radius andKey:key andAnimationTime:animationTime];
        }
        CLLocationCoordinate2D newPosition = CLLocationCoordinate2DMake(mapCircle.position.latitude, mapCircle.position.longitude);
        if (circle[@"latitude"]) {
            newPosition.latitude = latitude;
        }
        if (circle[@"longitude"]) {
            newPosition.longitude = longitude;
        }
        mapCircle.position = newPosition;
        
        if (circle[@"strokeColor"]) {
            mapCircle.strokeColor = [self getColor:circle[@"strokeColor"]];
        }
        if (circle[@"fillColor"]) {
            mapCircle.fillColor = [self getColor:circle[@"fillColor"]];
        }
       
        mapCircle.tappable = circle[@"tappable"];
        
        mapCircle.map = self;
        found[key] = mapCircle;
    }
    
    for(NSString *key in circles) {
        if (!found[key]) {
            PPTCircle *circle = circles[key];
            circle.map = nil;
        }
    }
    
    circles = found;

}

/**
 * Adds Polygon to the map.
 *
 * @return void
 */
- (void)setPolygons:(NSArray *)inPolygons
{
    NSMutableDictionary *found = [[NSMutableDictionary alloc] init];

    for (NSDictionary* polygon in inPolygons) {
        NSString *key = polygon[@"key"];
        
        PPTPolygon *mapPolygon = polygons[key];
        
        if (!mapPolygon) {
            NSMutableArray *arr = [[NSMutableArray alloc] init];
        
            GMSMutablePath *path = [[GMSMutablePath alloc] init];
        
            for(NSDictionary *inCoord in polygon[@"path"]) {
                CLLocationDegrees latitude = ((NSNumber*)inCoord[@"latitude"]).doubleValue;
                CLLocationDegrees longitude = ((NSNumber*)inCoord[@"longitude"]).doubleValue;

                CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitude, longitude);
                [path addCoordinate:coord];
            }
        
            mapPolygon = [PPTPolygon polygonWithPath:path andKey:key];
        }
        
        if (polygon[@"strokeColor"]) {
            mapPolygon.strokeColor = [self getColor:polygon[@"strokeColor"]];
        }
        if (polygon[@"fillColor"]) {
            mapPolygon.fillColor = [self getColor:polygon[@"fillColor"]];
        }
        mapPolygon.tappable = polygon[@"tappable"];
        
        found[key] = mapPolygon;
        mapPolygon.map = self;
    }
    
    for(NSString *key in polygons) {
        if (!found[key]) {
            PPTPolygon *polygon = polygons[key];
            polygon.map = nil;
        }
    }
    
    polygons = found;
}

/**
 * Adds marker icons to the map.
 *
 * @return void
 */
- (void)setMarkers:(NSArray *)inMarkers
{
    NSMutableDictionary *found = [[NSMutableDictionary alloc] init];
    
    for (NSDictionary* marker in inMarkers) {
        NSString *key = marker[@"key"];
        CLLocationDegrees latitude = ((NSNumber*)marker[@"latitude"]).doubleValue;
        CLLocationDegrees longitude = ((NSNumber*)marker[@"longitude"]).doubleValue;
        
        GMSMarker *mapMarker = markers[key];
        
        if (!mapMarker) {
            mapMarker = [PPTMarker markerWithPosition:CLLocationCoordinate2DMake(latitude, longitude) andKey:key];
        }
        mapMarker.position = CLLocationCoordinate2DMake(latitude, longitude);
        mapMarker.title = marker[@"title"] ? marker[@"title"] : nil;
        mapMarker.zIndex = ((NSNumber*)marker[@"zIndex"]).intValue;
        
        if (marker[@"icon"]) {
            UIImage *icon = [self getMarkerImage:marker];
            if (!marker[@"round"]) {
                mapMarker.icon = icon;
            }
            else {
                UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
                iconView.layer.cornerRadius = iconView.bounds.size.width / 2;
                iconView.clipsToBounds = true;
                iconView.layer.borderWidth = marker[@"borderWidth"] ? ((NSNumber*)marker[@"borderWidth"]).intValue  : 0.0;
                iconView.layer.borderColor = (marker[@"fillColor"] ? [self getColor:marker[@"fillColor"]] : [UIColor blackColor]).CGColor;
                
                mapMarker.iconView = iconView;
            }
            
        } else if (marker[@"fillColor"]) {
            UIColor *color = [self getColor:marker[@"fillColor"]];
            mapMarker.icon = [GMSMarker markerImageWithColor:color];
        }
        else {
            mapMarker.icon = nil;
        }
        
        mapMarker.map = self;
        found[key] = mapMarker;
    }
    
    for(NSString *key in markers) {
        if (!found[key]) {
            PPTMarker *marker = markers[key];
            marker.map = nil;
        }
    }
    
    markers = found;
}

/**
 * Get a UIColor from the marker's 'color' string
 * L...http://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
 *
 * @return UIColor
 */
- (UIColor *)getColor:(NSString *)hexString
{
    
    return [UIColor colorWithHexString:hexString];
    
#if 0
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:0.8];
#endif
}

/**
 * Load the marker image or use one that's already been loaded.
 *
 * @return NSImage
 */

- (UIImage *)image:(UIImage*)originalImage scaledToSize:(CGSize)size
{
    //avoid redundant drawing
    if (CGSizeEqualToSize(originalImage.size, size))
    {
        return originalImage;
    }
    
    //create drawing context
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    
    //draw
    [originalImage drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    
    //capture resultant image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return image
    return image;
}

- (UIImage *)getMarkerImage:(NSDictionary *)marker
{
    NSDictionary *bob = marker[@"icon"];
    NSString *sally = bob[@"uri"];
    
    NSString *markerPath = marker[@"icon"][@"uri"];
    
    if (!markerPath) {
        return nil;
    }
    
    if (!markerImages[markerPath]) {
        UIImage *markerImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:markerPath]]];
        
        if (!markerImage) {
            return nil;
        }
        
        UIImage *markerScaled = markerImage;
        
        CGFloat markerWidth = ((NSNumber*)marker[@"width"]).doubleValue;
        CGFloat markerHeight = ((NSNumber*)marker[@"height"]).doubleValue;
        
        if (markerWidth > 0 && markerHeight > 0) {
            markerScaled = [self image:markerImage scaledToSize:CGSizeMake(markerWidth, markerHeight)];
        }
        
        [markerImages setObject:markerScaled forKey:markerPath];
    }
    
    
    return markerImages[markerPath];
}

/**
 * Sets the user's location marker, if it has been enabled. Don't be alarmed if the marker looks funny when testing the app in
 * the simulator, there's a known bug: https://code.google.com/p/gmaps-api-issues/issues/detail?id=5472
 *
 * @return void
 */
- (void)setShowsUserLocation:(BOOL *)showsUserLocation
{
    if (showsUserLocation) {
        self.myLocationEnabled = YES;
    } else {
        self.myLocationEnabled = NO;
    }
}

/**
 * Controls whether scroll gestures are enabled (default) or disabled.
 *
 * @return void
 */
- (void)setScrollGestures:(BOOL *)scrollGestures
{
    if (scrollGestures) {
        self.settings.scrollGestures = YES;
    } else {
        self.settings.scrollGestures = NO;
    }
}

/**
 * Controls whether zoom gestures are enabled (default) or disabled.
 *
 * @return void
 */
- (void)setZoomGestures:(BOOL *)zoomGestures
{
    if (zoomGestures) {
        self.settings.zoomGestures = YES;
    } else {
        self.settings.zoomGestures = NO;
    }
}

/**
 * Controls whether tilt gestures are enabled (default) or disabled.
 *
 * @return void
 */
- (void)setTiltGestures:(BOOL *)tiltGestures
{
    if (tiltGestures) {
        self.settings.tiltGestures = YES;
    } else {
        self.settings.tiltGestures = NO;
    }
}

/**
 * Controls whether rotate gestures are enabled (default) or disabled.
 *
 * @return void
 */
- (void)setRotateGestures:(BOOL *)rotateGestures
{
    if (rotateGestures) {
        self.settings.rotateGestures = YES;
    } else {
        self.settings.rotateGestures = NO;
    }
}

/**
 * Controls whether gestures by users are completely consumed by the GMSMapView when gestures are enabled (default YES).
 *
 * @return void
 */
- (void)setConsumesGesturesInView:(BOOL *)consumesGesturesInView
{
    if (consumesGesturesInView) {
        self.settings.consumesGesturesInView = YES;
    } else {
        self.settings.consumesGesturesInView = NO;
    }
}

/**
 * Enables or disables the compass.
 *
 * @return void
 */
- (void)setCompassButton:(BOOL *)compassButton
{
    if (compassButton) {
        self.settings.compassButton = YES;
    } else {
        self.settings.compassButton = NO;
    }
}

/**
 * Enables or disables the My Location button.
 *
 * @return void
 */
- (void)setMyLocationButton:(BOOL *)myLocationButton
{
    if (myLocationButton) {
        self.settings.myLocationButton = YES;
    } else {
        self.settings.myLocationButton = NO;
    }
}

/**
 * Enables (default) or disables the indoor floor picker.
 *
 * @return void
 */
- (void)setIndoorPicker:(BOOL *)indoorPicker
{
    if (indoorPicker) {
        self.settings.indoorPicker = YES;
    } else {
        self.settings.indoorPicker = NO;
    }
}

/**
 * Controls whether rotate and zoom gestures can be performed off-center and scrolled around (default YES).
 *
 * @return void
 */
- (void)setAllowScrollGesturesDuringRotateOrZoom:(BOOL *)allowScrollGesturesDuringRotateOrZoom
{
    if (allowScrollGesturesDuringRotateOrZoom) {
        self.settings.allowScrollGesturesDuringRotateOrZoom = YES;
    } else {
        self.settings.allowScrollGesturesDuringRotateOrZoom = NO;
    }
}

@end
