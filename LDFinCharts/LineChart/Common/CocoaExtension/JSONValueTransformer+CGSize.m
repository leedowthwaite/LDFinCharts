//
//  JSONValueTransformer+CGSize.m
//  ChartMaker
//
//  Created by Lee Dowthwaite on 27/08/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "JSONValueTransformer+CGSize.h"

@implementation JSONValueTransformer (CGSize)

- (id)CGSizeFromNSString:(NSString *)string
{
    CGSize size = CGSizeFromString(string);
    return [NSValue valueWithCGSize:size];
}


- (id)JSONObjectFromCGSize:(CGSize)size
{
    return [NSString stringWithFormat:@"{%f, %f}", size.width, size.height];
}

@end
