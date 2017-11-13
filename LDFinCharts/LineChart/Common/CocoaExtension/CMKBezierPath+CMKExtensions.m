//
//  CMKBezierPath+CMKExtensions.m
//  ChartMaker
//
//  Created by Lee Dowthwaite on 27/08/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKBezierPath+CMKExtensions.h"

@implementation CMKBezierPath (CMKExtensions)

// dashPattern should be an array of NSNumbers representing a UIBezierPath dash pattern
- (void)setDashPatternFromArray:(NSArray *)dashPattern
{
    NSInteger nel = [dashPattern count];
    CGFloat dashes[nel];
    for (int i=0; i<nel; i++) dashes[i] = [dashPattern[i] floatValue];
    [self setLineDash:dashes count:nel phase:0];
}

@end
