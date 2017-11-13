//
//  CMKCustomPathModel.m
//  ChartMaker
//
//  Created by Lee Dowthwaite on 08/09/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKCustomPathModel.h"
#import "NSString+Extensions.h"

#pragma mark - CMKCustomPathElement

@implementation CMKCustomPathElement

@end


#pragma mark - CMKCustomPathModel

@implementation CMKCustomPathModel
{
    NSArray *_customPathList;
}

- (void)createCustomPaths
{
    _customPathList = [[self class] customPathsListForPathString:self.path];
}

- (void)addCustomPathsToPath:(CMKBezierPath *)path atPoint:(CGPoint)p0 size:(CGSize)size
{
    // this will be called whenever chart is moved or resized, so needs to be fairly efficient

    //NSLog(@"addCustomPathsToPath");

    if (!_customPathList)
    {
        // decode paths string just once, and store more optimally in _customPathList array
        [self createCustomPaths];
    }

    // a subpath is list created from subpath string e.g. "M(-1,-1),L(1,1)"
    for (NSArray *subpath in _customPathList)
    {
        [[self class] enumeratePrimitivesForPathElements:subpath withBlock:^(CMKCustomPathElement *element) {
            // relative path point
            CGPoint pr = [element.points[0] CGPointValue];
            // actual path point
            CGPoint p = CGPointMake(p0.x+pr.x*size.width*0.5f, p0.y+pr.y*size.height*0.5f);
            switch (element.type)
            {
                case CMKCustomPathElementTypeMoveToPoint:
                    BZPATH_MOVE_TO(path, p);
                    break;
                case CMKCustomPathElementTypeAddLineToPoint:
                    BZPATH_LINE_TO(path, p);
                    break;
                case CMKCustomPathElementTypeArcWithCenter:
                {
                    // for a circle: "M(1,0),A(0,0)"
                    BZPATH_ARC_WITH_CENTER(path, p, size.width*0.5f);
                    break;
                }
                case CMKCustomPathElementTypeAddQuadCurveToPoint:
//                    [points addObject:[NSValue valueWithCGPoint:element->points[1]]];
                    break;
                case CMKCustomPathElementTypeAddCurveToPoint:
//                    [points addObject:[NSValue valueWithCGPoint:element->points[2]]];
                    break;
                default:
                    break;
            }
        }];
        [path closePath];   // subpath done
    }
}


// create list of custom paths from the supplied custom path string
// custom paths are implicitly delineated by a closepath primitive
// should only need to call this once
+ (NSArray *)customPathsListForPathString:(NSString *)pathString
{
    NSMutableArray *pathsList = [NSMutableArray arrayWithCapacity:4];
    // paths list is for entire string e.g. "M(-1,-1),L(1,1);M(1,-1),L(-1,1)"
    for (NSString *subpath in [pathString componentsSeparatedByString:@";"])
    {
        [pathsList addObject:[self elementsForSubpathString:subpath]];
    }
    return pathsList;
}

// create list of elements for a subpath string
+ (NSArray *)elementsForSubpathString:(NSString *)subpath
{
    NSMutableArray *elements = [NSMutableArray arrayWithCapacity:8];

    // e.g. "M(-1,-1),L(1,1)"
    NSArray *matches = [subpath matchesWithRegexPattern:@"([A-Z])\\(([-.0-9]+),([-.0-9]+)\\)"];
    for (NSTextCheckingResult *match in matches)
    {
        NSRange r = [match rangeAtIndex:1];
        char mnemonic = [[subpath substringWithRange:r] characterAtIndex:0];
        r = [match rangeAtIndex:2];
        CGFloat x = [[subpath substringWithRange:r] floatValue];
        r = [match rangeAtIndex:3];
        CGFloat y = [[subpath substringWithRange:r] floatValue];

        //NSLog(@"mnemonic %c point (%0.3f,%0.3f)", mnemonic, x, y);

        NSMutableArray *points = [NSMutableArray arrayWithCapacity:1];
        CMKCustomPathElement *element = [[CMKCustomPathElement alloc] init];
        CGPoint p0 = CGPointMake(x, y);
        [points addObject:[NSValue valueWithCGPoint:p0]];
        
        switch (mnemonic)
        {
            case 'M':
                element.type = CMKCustomPathElementTypeMoveToPoint;
                break;
            case 'L':
                element.type = CMKCustomPathElementTypeAddLineToPoint;
                break;
            case 'A':
                element.type = CMKCustomPathElementTypeArcWithCenter;
                break;
            case 'Q':
                element.type = CMKCustomPathElementTypeAddQuadCurveToPoint;
                // TODO: add more points
                //[points addObject:[NSValue valueWithCGPoint:element->points[1]]];
                break;
            case 'C':
                element.type = CMKCustomPathElementTypeAddCurveToPoint;
                // TODO: add more points
                //[points addObject:[NSValue valueWithCGPoint:element->points[2]]];
                break;
            default:
                // unknown primitive mnemonic
                assert(0);
                break;
        }
        element.points = points;
        
        [elements addObject:element];
    }
    return elements;
}


+ (void)enumeratePrimitivesForPathElements:elements withBlock:(CustomPathElementBlock)block
{
    // enumerate each subpath (because we inject closepath primitives between them)
    for (CMKCustomPathElement *element in elements)
    {
        block(element);
    }
}

@end
