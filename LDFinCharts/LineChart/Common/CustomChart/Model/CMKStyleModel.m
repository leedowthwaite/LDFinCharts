//
//  StyleModel.m
//  ChartMaker
//
//  Created by Lee Dowthwaite on 02/04/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKStyleModel.h"


@implementation CMKLineStyleModel

// to make all properties (including scalars) optional
+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

- (NSString * const)lineEndCapStyleAsCAString
{
    switch (self.lineEndCapStyle)
    {
        case CMKLineEndCapStyleSquare: return kCALineCapSquare;
        case CMKLineEndCapStyleRound: return kCALineCapRound;
        default:
        case CMKLineEndCapStyleButt: return kCALineCapButt;
    }
}


- (NSString * const)lineJoinStyleAsCAString
{
    switch (self.lineJoinStyle)
    {
        case CMKLineJoinStyleBevel: return kCALineJoinBevel;
        case CMKLineJoinStyleRound: return kCALineJoinRound;
        default:
        case CMKLineJoinStyleMiter: return kCALineJoinMiter;
    }
}

- (NSArray *)dashPatternAsArray
{
    NSArray *elements = [self.dashPattern componentsSeparatedByString:@","];
    NSMutableArray *pattern = [NSMutableArray arrayWithCapacity:[elements count]];
    for (NSString *s in elements)
    {
        [pattern addObject:@([s floatValue])];
    }
    return pattern;
}

@end


@implementation CMKStyleModel


// to make all properties (including scalars) optional
+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

- (unsigned int)colorValue
{
    if (self.rgbColorCode)
    {
        NSString *hexString = [self.rgbColorCode stringByReplacingOccurrencesOfString:@"#" withString:@"0x"];
        unsigned int val = (int)strtol([hexString UTF8String], NULL, 0);
        if (val <= 0x00ffffff) val |= 0xff000000;
        return val;
    }
    else
    {
        return 0;
    }
}


@end
