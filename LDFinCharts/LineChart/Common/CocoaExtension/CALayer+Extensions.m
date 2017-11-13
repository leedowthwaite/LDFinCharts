//
//  CALayer+Extensions.m
//  ChartMaker
//
//  Created by Lee Dowthwaite on 02/09/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CALayer+Extensions.h"

@implementation CALayer (Extensions)

- (CALayer *)sublayerNamed:(NSString *)name
{
    for (CALayer *layer in self.sublayers)
    {
        if ([layer.name isEqualToString:name]) return layer;
    }
    return nil;
}

@end
