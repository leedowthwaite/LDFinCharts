//
//  CMKTickMarksModel.m
//  ChartMaker
//
//  Created by Lee Dowthwaite on 09/09/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKTickMarksModel.h"

@implementation CMKTickMarksModel

// to make all properties (including scalars) optional
+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}


- (void)addTickMarkToPath:(CMKBezierPath *)path atPoint:(CGPoint)p
{
    if (self.style == CMKTickMarkStyleCustomPath)
    {
        if (self.customPath)
        {
            [self.customPath addCustomPathsToPath:path atPoint:p size:self.size];
        }
        else
        {
            NSLog(@"Warning: custom path type specified but no custom path found.");
        }
    }
    else
    {
        [[self class] addTickMarkToPath:path atPoint:p size:self.size withStyle:self.style];
    }
}


+ (void)addTickMarkToPath:(CMKBezierPath *)path atPoint:(CGPoint)p size:(CGSize)size withStyle:(CMKTickMarkStyle)style
{
    switch (style)
    {
        case CMKTickMarkStyleCross:
            [self addCrossToPath:path atPoint:p size:size];
            break;
        case CMKTickMarkStyleDot:
            [self addDotToPath:path atPoint:p size:size];
            break;
        case CMKTickMarkStyleHorizontalMark:
            [self addHorizontalMarkToPath:path atPoint:p size:size];
            break;
        case CMKTickMarkStyleVerticalMark:
            [self addVerticalMarkToPath:path atPoint:p size:size];
            break;
        default:
            break;
    }
}

+ (void)addCrossToPath:(CMKBezierPath *)path atPoint:(CGPoint)p size:(CGSize)size
{
    BZPATH_MOVE_TO(path, CGPointMake(p.x-size.width*0.5f, p.y));
    BZPATH_LINE_TO(path, CGPointMake(p.x+size.width*0.5f, p.y));
    [path closePath];
    BZPATH_MOVE_TO(path, CGPointMake(p.x, p.y-size.height*0.5f));
    BZPATH_LINE_TO(path, CGPointMake(p.x, p.y+size.height*0.5f));
    [path closePath];
}

+ (void)addDotToPath:(CMKBezierPath *)path atPoint:(CGPoint)p size:(CGSize)size
{
    BZPATH_MOVE_TO(path, CGPointMake(p.x-size.width*0.5f, p.y-size.height*0.5f));
    BZPATH_LINE_TO(path, CGPointMake(p.x-size.width*0.5f, p.y+size.height*0.5f));
    BZPATH_LINE_TO(path, CGPointMake(p.x+size.width*0.5f, p.y+size.height*0.5f));
    BZPATH_LINE_TO(path, CGPointMake(p.x+size.width*0.5f, p.y-size.height*0.5f));
    [path closePath];
}

+ (void)addHorizontalMarkToPath:(CMKBezierPath *)path atPoint:(CGPoint)p size:(CGSize)size
{
    BZPATH_MOVE_TO(path, CGPointMake(p.x-size.width*0.5f, p.y));
    BZPATH_LINE_TO(path, CGPointMake(p.x+size.width*0.5f, p.y));
    [path closePath];
}

+ (void)addVerticalMarkToPath:(CMKBezierPath *)path atPoint:(CGPoint)p size:(CGSize)size
{
    BZPATH_MOVE_TO(path, CGPointMake(p.x, p.y-size.height*0.5f));
    BZPATH_LINE_TO(path, CGPointMake(p.x, p.y+size.height*0.5f));
    [path closePath];
}

@end
