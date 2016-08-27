//
//  UIColor+HexString.h
//  PPTMapView
//
//  Created by John Cwikla on 8/27/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#ifndef UIColor_HexString_h
#define UIColor_HexString_h

#import <UIKit/UIColor.h>

@interface UIColor(HexString)

+ (UIColor *) colorWithHexString: (NSString *) hexString;

@end

#endif /* UIColor_HexString_h */
