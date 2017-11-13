//
//  CMKColorModel.m
//  ChartMaker
//
//  Created by Lee Dowthwaite on 02/04/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKColorModel.h"

@implementation CMKColorModel


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

- (CMKColor *)color
{
    return [CMKColor colorWithARGB:[self colorValue]];
}

@end
