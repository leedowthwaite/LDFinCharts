//
//  ChartYAxis.m
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 03/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "ChartYAxis.h"
#import "ChartSeries.h"
#import "UIBezierPath+TextSupport.h"

@implementation ChartYAxis

// override
- (CMKBezierPath *)bezierPathForAxisForSeries:(ChartSeries *)series
{
    if (!series || series.count == 0) return nil;
    CMKBezierPath *path = [self pathForYAxis];
    //[self setLinePatternOnPath:path forStyle:self.model.lineStyle];
    return path;
}

// override
+ (ChartAxis *)axisWithModel:(ChartAxisModel *)model
{
    ChartYAxis *axis = [[ChartYAxis alloc] initWithModel:model];
     return axis;
}

// override
- (void)addSeries:(ChartSeries *)series
{
    [super addSeries:series];
    series.yAxis = self;
}

// override
- (CMKBezierPath *)bezierPathForAxisGridlinesForSeries:(ChartSeries *)series major:(BOOL)major
{
    if (major) return nil;
    
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    [self enumerateAxisGridlinesForSeries:series block:^(CGPoint gridlineViewPointStart, CGPoint gridlineViewPointEnd, NSString *label) {
        CMKBezierPath *divPath = [CMKBezierPath bezierPath];
        //[divPath moveToPoint:gridlineViewPointStart];
        BZPATH_MOVE_TO(divPath, gridlineViewPointStart);
        //[divPath addLineToPoint:gridlineViewPointEnd];
        BZPATH_LINE_TO(divPath, gridlineViewPointEnd);
        //[path appendPath:divPath];
        BZPATH_APPEND(path, divPath);
    }];
    //[self setLinePatternOnPath:path forStyle:self.model.gridlinesStyle];
    return path;
}


// returns the x position of the axis
- (CGFloat)axisX
{
    CGRect rect = [self.delegate axisViewBounds];
    CGFloat x;
    CGFloat x0 = rect.origin.x;
    CGFloat x1 = rect.origin.x+rect.size.width-1;
    
    switch (self.model.position)
    {
        // forced top axis
        case CMKAxisPositionLeft:
            x = x0;
            break;
        // forced bottom axis
        case CMKAxisPositionRight:
            x = x1;
            break;
        // natural axis position
        case CMKAxisPositionNone:
        default:
        {
            // position for axis line in data
            CGPoint p0;
            if (self.zoomWindow)
            {
                p0 = [self.series mapPoint:CGPointMake(0, 0) toViewRect:[self.delegate dataViewBounds] zoomWindow:*self.zoomWindow];
            }
            else
            {
                p0 = [self.series mapPoint:CGPointMake(0, 0) toViewRect:[self.delegate dataViewBounds]];
            }
            // if natural axis line falls outside view, clamp to top or bottom
            x = p0.x;
            if (x < x0) x = x0;
            else if (x > x1) x = x1;
            break;
        }
    }
    return x;
}

// Returns the visual position of the axis for the data. If position is natural but the axis is off-screen,
// the axis will be clamped and effectively behave as Top or Bottom.
- (CMKAxisPosition)effectiveAxisPosition
{
    CMKAxisPosition pos = self.model.position;
    switch (self.model.position)
    {
        case CMKAxisPositionNone:
        {
            CGFloat x = [self axisX];
            CGRect rect = [self.delegate axisViewBounds];
            CGFloat x0 = rect.origin.x;
            CGFloat x1 = rect.origin.x+rect.size.width-1;
            if (x <= x0)
            {
                pos = CMKAxisPositionLeft;
            }
            else if (x >= x1)
            {
                pos = CMKAxisPositionRight;
            }
            break;
        }
        default:
            break;
    }
    return pos;
}

#pragma mark - axis path generation

- (CMKBezierPath *)pathForYAxis
{
    CGRect rect = [self.delegate axisViewBounds];
    CGFloat x = [self axisX];
    //NSLog(@"pathForYAxis: rect: %@ x: %f", NSStringFromCGRect(rect), x);
    BZPATH *path = [BZPATH bezierPath];
    BZPATH_MOVE_TO(path,CGPointMake(x,rect.origin.y));
    BZPATH_LINE_TO(path,CGPointMake(x,rect.origin.y+rect.size.height-1));
    return path;
}

- (CMKBezierPath *)pathForYAxisOverlayForDataPoint:(ChartDataPoint *)dataPoint inViewRect:(CGRect)viewRect
{
    // point in data space
    CGPoint dp = [self.series dataSpacePointForDataPoint:dataPoint];
    // convert to point in view
    CGPoint p = [self mapPoint:dp toViewRect:viewRect];

    BZPATH *path = [BZPATH bezierPath];
    BZPATH_MOVE_TO(path,CGPointMake(viewRect.origin.x, p.y));
    BZPATH_LINE_TO(path,CGPointMake(viewRect.origin.x+viewRect.size.width-1, p.y));
    return path;
}


- (CMKBezierPath *)pathForYAxisOverlayLabelForDataPoint:(ChartDataPoint *)dataPoint inViewRect:(CGRect)viewRect
{
    // point in data space
    CGPoint dp = [self.series dataSpacePointForDataPoint:dataPoint];
    // convert to point in view
    CGPoint p = [self mapPoint:dp toViewRect:viewRect];

    NSString *string = [self formattedStringWithFloat:dataPoint.yValue.valueAsFloat];
    CMKFont *font = [CMKFont fontWithName:self.model.labelsStyle.fontName size:self.model.labelsStyle.fontSize];
    CGRect labelRect = [self labelBoundsForString:string withFont:font atPoint:p inViewRect:viewRect];

    CMKBezierPath *path = [CMKBezierPath bezierPath];
    BOOL inside = self.model.labelsPosition == CMKLabelsPositionInside;
    if (!inside || CGRectContainsRect(viewRect, labelRect))
    {
        path = [CMKBezierPath bezierPathFromString:string withFont:font inRect:labelRect];
    }

    return path;
}

- (CMKBezierPath *)pathForYAxisOverlayLabelOutlineForDataPoint:(ChartDataPoint *)dataPoint inViewRect:(CGRect)viewRect
{
    // point in data space
    CGPoint dp = [self.series dataSpacePointForDataPoint:dataPoint];
    // convert to point in view
    CGPoint p = [self mapPoint:dp toViewRect:viewRect];

    NSString *string = [self formattedStringWithFloat:dataPoint.yValue.valueAsFloat];
    CMKFont *font = [CMKFont fontWithName:self.model.labelsStyle.fontName size:self.model.labelsStyle.fontSize];
    CGRect labelRect = [self labelBoundsForString:string withFont:font atPoint:p inViewRect:viewRect];

    return [CMKBezierPath bezierPathWithRect:labelRect];
}

- (CGRect)labelBoundsForString:(NSString *)string withFont:(CMKFont *)font atPoint:(CGPoint)p inViewRect:(CGRect)viewRect
{
    BOOL inside = self.model.labelsPosition == CMKLabelsPositionInside;
    CGFloat labelMargin = self.model.labelMargin;
    CMKAxisPosition axisPos = [self effectiveAxisPosition];
    BOOL farOrigin = axisPos == CMKAxisPositionRight;

    CGSize size = [string sizeWithAttributes:@{NSFontAttributeName:font}];
    CGFloat labelOffset = (inside ? (size.width+labelMargin) : -(size.width+labelMargin));
    if (farOrigin) labelOffset = -labelOffset;
    CGFloat labelOrigin = (farOrigin ? viewRect.origin.x+viewRect.size.width : viewRect.origin.x);
    return CGRectMake(labelOrigin+labelOffset, p.y-size.height*0.5f, size.width, size.height);
}



// draw the bezier path for the tickmarks, as defined by the supplied model.
// May be called an arbitrary number of times; the model's position property determines if/where the tickmarks are drawn.
- (CMKBezierPath *)tickmarksBezierPathForModel:(CMKTickMarksModel *)model
{
    CGRect axisBounds = [self.delegate axisViewBounds];
    // determine the origin for the axis (near/far)
    BOOL farOrigin = self.model.position == CMKAxisPositionRight;
    // the model's position property determines drawing logic
    CMKTickmarksPosition pos = model.position;
    CGSize size = model.size;

    CMKBezierPath *path = [CMKBezierPath bezierPath];
    [self enumerateAxisGridlinesForSeries:self.series block:^(CGPoint gridlineViewPointStart, CGPoint gridlineViewPointEnd, NSString *label) {
        
        //const CGFloat kSize = 10.0f;
        CGFloat hs = size.width * 0.5f;
        //NSLog(@"model tag %@", model.tag);

        CMKAxisPosition axisPos = [self effectiveAxisPosition];
        BOOL right = axisPos == CMKAxisPositionRight;

        CGFloat x0 = axisBounds.origin.x;
        CGFloat x1 = axisBounds.origin.x+axisBounds.size.width;
        CGFloat nearX = (right ? x1 : x0);
        CGFloat farX = (right ? x0 : x1);


        if (axisPos == CMKAxisPositionNone)
        {
            CGFloat axisX = [self axisX];
            // normal setting - axis is on a zero line somewhere between top and bottom
            CGPoint p0;
            if (pos & CMKTickmarksPositionNear)
            {
                // zero line is the near tickmark
                //NSLog(@"drawing path for near = zero");
                p0 = CGPointMake(axisX, gridlineViewPointStart.y);
                [self addTickmarkToPath:path forModel:model atPosition:p0 height:hs near:YES];
            }
            if (pos & CMKTickmarksPositionFar)
            {
                //NSLog(@"drawing path for far = top");
                // far top
                p0 = CGPointMake(axisBounds.origin.x, gridlineViewPointStart.y);
                [self addTickmarkToPath:path forModel:model atPosition:p0 height:hs near:YES];
                // far bottom
                //NSLog(@"drawing path for far = bottom");
                p0 = CGPointMake(axisBounds.origin.x+axisBounds.size.width, gridlineViewPointStart.y);
                [self addTickmarkToPath:path forModel:model atPosition:p0 height:hs near:NO];
            }
        }
        else
        {


            // axis is at top or bottom
            if (pos & CMKTickmarksPositionNear)
            {
                // near
                CGPoint p0 = CGPointMake(nearX, gridlineViewPointStart.y);
                [self addTickmarkToPath:path forModel:model atPosition:p0 height:hs near:!right];
            }
            if (pos & CMKTickmarksPositionFar)
            {
                // far
                CGPoint p0 = CGPointMake(farX, gridlineViewPointStart.y);
                [self addTickmarkToPath:path forModel:model atPosition:p0 height:hs near:right];
            }

        }
        
    }];
    return path;
}


- (void)addTickmarkToPath:(CMKBezierPath *)path forModel:(CMKTickMarksModel *)model atPosition:(CGPoint)p0 height:(CGFloat)h near:(BOOL)near
{
    CMKTickmarksPosition pos = model.position;
    
    if (pos & CMKTickmarksPositionInside)
    {
        p0.x = p0.x + (near ? h : -h);
    }
    if (pos & CMKTickmarksPositionOutside)
    {
        p0.x = p0.x - (near ? h : -h);
    }
    CMKBezierPath *divPath = [CMKBezierPath bezierPath];
    [model addTickMarkToPath:path atPoint:p0];
    BZPATH_APPEND(path, divPath);
}


- (void)enumerateAxisGridlinesForSeries:(ChartSeries *)series block:(YAxisEnumerationBlock)block
{
//    CGRect axisBounds = [self.delegate axisViewBounds];
//    CGRect dataBounds = [self.delegate dataViewBounds];
//
//    CGFloat axisPaddingScaleFactor = dataBounds.size.height / axisBounds.size.height;

    CGFloat minY = series.minY;
    CGFloat maxY = series.maxY;
    CGFloat yRange = maxY-minY;

    if (yRange == 0)
    {
        // if data is flat, we can have a yRange of zero, which leads to div-by-zero conditions, so prevent this
        NSLog(@"Warning: enumerateAxisGridlinesForSeries: yRange is zero, artificially setting to 1 to prevent maths errors");
        yRange = maxY*2.0f;
    }

    CGFloat minX = (CGFloat)[series.minTimeX timeIntervalSince1970];

    int exponent = (int)floor(log10f(yRange));
    CGFloat magnitude = pow(10, exponent);
    assert(magnitude >= 0);
    
    CGFloat mantissa = (yRange/magnitude);
    int roundMantissa = (int)ceilf(mantissa);
    int ndiv;
    CGFloat division;
    do
    {
        CGFloat normdiv = 1.0f;
        // choose a nice division: 0.2, 0.25, 0.5, 1 or 2
        switch (roundMantissa)
        {
            case 1:
            case 2:
                normdiv = 0.2f; break;
            case 3:
                normdiv = 0.25f; break;
            case 4:
                normdiv = 0.5f; break;
            case 5:
            case 6:
                normdiv = 1.0f; break;
            case 7:
            case 8:
            case 9:
            case 10:    // can reach 10 because of round-up
                normdiv = 2.0f; break;
            default:
                NSLog(@"Fatal error: enumerateAxisGridlinesForSeries: unhandled roundMantissa");
                assert(0);  // unhandled roundMantissa
                break;
        }

        division = magnitude*normdiv;
        ndiv = (int)(yRange/division);
        // most times the first division we pick will be OK, but if we end up with too many divs, bump the mantissa and iterate
        if (++roundMantissa >= 10) break;   // should never happen but for safety
    } while (ndiv > 5);
    
    //NSLog(@"minY %0.2f maxY %0.2f yRange %0.2f mantissa %0.2f roundMantissa %d exponent %d magnitude %d division %0.2f ndiv %d", minY, maxY, yRange, mantissa, roundMantissa, exponent, magnitude, division, ndiv);

    int baseDiv = (int)(minY/division);
    
    
    CGRect axisBounds = [self.delegate axisViewBounds];
    CGRect dataBounds = [self.delegate dataViewBounds];

    //BOOL rightAxis = self.model.position == CMKAxisPositionRight;
    CMKAxisPosition axisPos = [self effectiveAxisPosition];
    BOOL rightAxis = axisPos == CMKAxisPositionRight;


    CGFloat gridlinesRightBleed = (rightAxis ? self.model.gridlinesNearBleed : self.model.gridlinesFarBleed);
    CGFloat gridlinesLeftBleed = (rightAxis ? self.model.gridlinesFarBleed : self.model.gridlinesNearBleed);

    for (int i=baseDiv; i<=baseDiv+ndiv+1; i++)
    {
        CGFloat divY = i * division;
        CGPoint p0 = [series mapPoint:CGPointMake(minX, divY) toViewRect:dataBounds];
        if (p0.x < 0)
        {
            p0.x = 0;
        }
        // p0 is axis-aligned gridline origin
        
        // gridline runs on p0.y, between x bounds determined by axisBounds and bleed
        CGPoint pg0 = CGPointMake(axisBounds.origin.x-gridlinesLeftBleed, p0.y);
        CGPoint pg1 = CGPointMake(axisBounds.origin.x+axisBounds.size.width + gridlinesRightBleed-1, p0.y);

        if (CGRectContainsPoint(axisBounds, p0))
        {
            // if p0 falls within axis bounds, gridline should be displayed
//            NSString *text = [NSString stringWithFormat:@"%0.2f",divY];
            NSString *text = [self formattedStringWithFloat:divY];
            // invoke caller's block
            block(pg0, pg1, text);
        }
    }
    
}


- (CMKBezierPath *)bezierPathForAxisLabelsForSeries:(ChartSeries *)series
{
    BOOL inside = self.model.labelsPosition == CMKLabelsPositionInside;
    //BOOL farOrigin = self.model.position == CMKAxisPositionRight;
    CGFloat labelMargin = self.model.labelMargin;
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    CGRect bounds = [self.delegate axisViewBounds];
    CMKAxisPosition axisPos = [self effectiveAxisPosition];
    BOOL farOrigin = axisPos == CMKAxisPositionRight;
    
    CMKFont *font = [CMKFont fontWithName:self.model.labelsStyle.fontName size:self.model.labelsStyle.fontSize];
    [self enumerateAxisGridlinesForSeries:series block:^(CGPoint gridlineViewPointStart, CGPoint gridlineViewPointEnd, NSString *label) {
        CGSize size = [label sizeWithAttributes:@{NSFontAttributeName:font}];
        CGFloat labelOffset = (inside ? (size.width+labelMargin) : -(size.width+labelMargin));
        if (farOrigin) labelOffset = -labelOffset;
        CGFloat labelOrigin = (farOrigin ? bounds.origin.x+bounds.size.width : bounds.origin.x);
        CGRect labelRect = CGRectMake(labelOrigin+labelOffset, gridlineViewPointStart.y-size.height*0.5f, size.width, size.height);
        if (!inside || CGRectContainsRect(bounds, labelRect))
        {
            CMKBezierPath *labelPath = [CMKBezierPath bezierPathFromString:label withFont:font inRect:labelRect];
            [path appendPath:labelPath];
        }
    }];
    return path;
}



@end
