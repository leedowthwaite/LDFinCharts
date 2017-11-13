//
//  UIColor+ABFExtensions.h
//  Autobahn
//
//  Created by Lee Dowthwaite on 12/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CMKType.h"

@interface CMKColor (CMKExtensions)
+ (CMKColor *)colorWithARGB:(UInt32)argb;
- (CMKColor *)lighterColor;
- (CMKColor *)colorDarkenedBy:(CGFloat)factor;
- (NSString *)rgbColorString;

@end
