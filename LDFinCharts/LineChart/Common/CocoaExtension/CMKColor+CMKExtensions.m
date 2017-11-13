//
//  CMKColor+ABFExtensions.m
//  Autobahn
//
//  Created by Lee Dowthwaite on 12/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CMKColor+CMKExtensions.h"

@implementation CMKColor (CMKExtensions)

+ (CMKColor *)colorWithARGB:(UInt32)argb
{
    CGFloat a = (CGFloat)((argb>>24) & 0xff);
    if (a == 0) a = 0xff;
    CGFloat r = (CGFloat)((argb>>16) & 0xff);
    CGFloat g = (CGFloat)((argb>>8) & 0xff);
    CGFloat b = (CGFloat)((argb>>0) & 0xff);
    return [CMKColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a/255.0f];
}

- (CMKColor *)lighterColor
{
    CGFloat h,s,b,a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    return [CMKColor colorWithHue:h
                      saturation:MAX(s - 0.3, 0.0)
                      brightness:b /*MIN(b * 1.3, 1.0)*/
                           alpha:a];
}

- (CMKColor *)colorDarkenedBy:(CGFloat)factor
{
    CGFloat h,s,b,a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    return [CMKColor colorWithHue:h
                      saturation:s
                      brightness:b * (1.0f-factor)
                           alpha:a];
}

// return a string of form "#RRGGBB"
- (NSString *)rgbColorString
{
    long n;
#if TARGET_OS_IPHONE
    n = CGColorGetNumberOfComponents(self.CGColor);
#else
    n = [self numberOfComponents];
#endif
#if TARGET_OS_IPHONE
    const CGFloat *comp = CGColorGetComponents(self.CGColor);
#else
    CGFloat comp[n];
    [self getComponents:comp];
#endif
    NSMutableString *s = [NSMutableString stringWithString:@"#"];
    if (n > 3) n = 3;
    for (int i=0; i<n; i++)
    {
        // in order 0..3 = r,g,b,a
        int c = 255.0f * comp[i];
        //NSLog(@"i %d comp[i] %f c %04x", i, comp[i], c);
        [s appendFormat:@"%02x",c];
    }
    return s;
}


@end
