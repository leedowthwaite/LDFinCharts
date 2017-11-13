//
//  ChartXAxis.m
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 03/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "ChartXAxis.h"
#import "ChartSeries.h"
#import "NSDate+ChartFormatting.h"
#import "UIBezierPath+TextSupport.h"
#import "ChartYAxis.h"
#import "ChartContiguousPeriodDescriptor.h"
#import "CMKAxisGridlineDescriptor.h"

static const NSTimeInterval kSpecialPeriod1min = 60;
static const NSTimeInterval kSpecialPeriod5min = 5*kSpecialPeriod1min;
static const NSTimeInterval kSpecialPeriod15min = 15*kSpecialPeriod1min;
static const NSTimeInterval kSpecialPeriod30min = 30*kSpecialPeriod1min;
static const NSTimeInterval kSpecialPeriod1h = kSpecialPeriod1min*60;
static const NSTimeInterval kSpecialPeriod4h = 4*kSpecialPeriod1h;
static const NSTimeInterval kSpecialPeriod24h = 24*kSpecialPeriod1h;
static const NSTimeInterval kSpecialPeriod2d = 2*kSpecialPeriod24h;
static const NSTimeInterval kSpecialPeriod5d = 5*kSpecialPeriod24h;
static const NSTimeInterval kSpecialPeriod7d = 7*kSpecialPeriod24h;
static const NSTimeInterval kSpecialPeriod30d = 30*kSpecialPeriod24h;
static const NSTimeInterval kSpecialPeriod3m = 3*kSpecialPeriod30d;
static const NSTimeInterval kSpecialPeriod6m = 6*kSpecialPeriod30d;
static const NSTimeInterval kSpecialPeriod12m = 12*kSpecialPeriod30d;

@interface ChartXAxis()
{
    NSString *_dateFormatterTemplate;
    NSString *_majorDateFormatterTemplate;
    NSString *_overlayDateFormatterTemplate;
    NSDateFormatter *_dateFormatter;
    NSDateFormatter *_majorDateFormatter;
    NSDateFormatter *_overlayDateFormatter;
}
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *majorDateFormatter;
@property (nonatomic, strong) NSDateFormatter *overlayDateFormatter;
@property (nonatomic, strong) NSArray *gridlineDescriptors;

@property (nonatomic, assign) NSTimeInterval interdayDurationAdj;
@property (nonatomic, assign) NSTimeInterval axisRange;
@property (nonatomic, assign) NSTimeInterval smallestMinorDivision;
@property (nonatomic, assign) NSTimeInterval paddingRange;

@end

@implementation ChartXAxis

+ (ChartAxis *)axisWithJSONDict:(NSDictionary *)dict
{
    ChartXAxis *axis = [[ChartXAxis alloc] init];
//    NSData *data = [dict dataUsing]
//    axis.model = [CMKSerializableModel modelWithData:data];
    return axis;
}

// override
+ (ChartAxis *)axisWithModel:(ChartAxisModel *)model
{
    if (model)
    {
        ChartXAxis *axis = [[ChartXAxis alloc] initWithModel:model];
        return axis;
    }
    return nil;
}

// override
- (void)addSeries:(ChartSeries *)series
{
    [super addSeries:series];
    series.xAxis = self;
}


// override
- (CMKBezierPath *)bezierPathForAxisForSeries:(ChartSeries *)series
{
    if (!series || series.count == 0) return nil;
    CMKBezierPath *path = [self pathForXAxis];
    //&&&[self setLinePatternOnPath:path forStyle:self.model.lineStyle];
    return path;
}


// returns the y position of the axis
- (CGFloat)axisY
{
    CGRect rect = [self.delegate axisViewBounds];
    CGFloat y;
    CGFloat y0 = rect.origin.y;
    CGFloat y1 = rect.origin.y+rect.size.height-1;
    
    switch (self.model.position)
    {
        // forced top axis
        case CMKAxisPositionTop:
            y = y0;
            break;
        // forced bottom axis
        case CMKAxisPositionBottom:
            y = y1;
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
            y = p0.y;
            if (y < y0) y = y0;
            else if (y > y1) y = y1;
            break;
        }
    }
    return y;
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
            CGFloat y = [self axisY];
            CGRect rect = [self.delegate axisViewBounds];
            CGFloat y0 = rect.origin.y;
            CGFloat y1 = rect.origin.y+rect.size.height-1;
            if (y <= y0)
            {
                pos = CMKAxisPositionTop;
            }
            else if (y >= y1)
            {
                pos = CMKAxisPositionBottom;
            }
            break;
        }
        default:
            break;
    }
    return pos;
}

- (CMKBezierPath *)pathForXAxisOverlayAtViewPosition:(CGPoint)point
{
    CGRect rect = [self.delegate axisViewBounds];
    BZPATH *path = [BZPATH bezierPath];
    BZPATH_MOVE_TO(path,CGPointMake(point.x,rect.origin.y));
    BZPATH_LINE_TO(path,CGPointMake(point.x,rect.origin.y+rect.size.height-1));
    return path;
}

- (CMKBezierPath *)pathForXAxisOverlayIntersectionAtViewPosition:(CGPoint)point
{
    CGRect viewRect = [self.delegate axisViewBounds];
    ChartDataPoint *dataPoint = [self dataPointForViewPosition:point inViewRect:viewRect];
    // point in data space
//    CGPoint dp = [self.series dataSpacePointForDataPoint:dataPoint];
    CGPoint dp = [self.series relativeDataSpacePointForDataPoint:dataPoint];
    // convert to point in view
    CGPoint p = [self mapPoint:dp toViewRect:viewRect];
//    if (self.zoomWindow)
//    {
//        p = [self.series mapPoint:dp toViewRect:viewRect zoomWindow:*self.zoomWindow];
//    }
//    else
//    {
//        p = [self.series mapPoint:dp toViewRect:viewRect];
//    }
    // draw a circle
    BZPATH *path = [BZPATH bezierPath];
    BZPATH_ARC_WITH_CENTER(path, p, 2);
    return path;
}


// Given a point in the view (e.g. from a touch), returns the chart data point it most closely maps to
//
- (ChartDataPoint *)dataPointForViewPosition:(CGPoint)point inViewRect:(CGRect)viewRect
{
    double x = [self dataSpacePositionForX:point.x inViewRect:viewRect];
//    NSInteger index = [self.series dataPointIndexForStartXValue:(double)x];
    NSInteger index = [self.series dataPointIndexForStartXValueRelative:(double)x];
    ChartDataPoint *dataPoint = [self.series dataPointAtIndex:index];
    //NSLog(@"dataPoint %@", dataPoint);
    return dataPoint;
}

// Given a point in the view (e.g. from a touch), returns the data space x position for it
//
- (double)dataSpacePositionForX:(CGFloat)x inViewRect:(CGRect)viewRect
{
    double dx;
    if (self.zoomWindow)
    {
        dx = [self.series mapViewX:x fromViewRect:viewRect zoomWindow:*self.zoomWindow];
    }
    else
    {
        dx = [self.series mapViewX:x fromViewRect:viewRect];
    }
    return dx;
}

- (CMKBezierPath *)pathForXAxis
{
    CGRect rect = [self.delegate axisViewBounds];
    CGFloat y = [self axisY];
    //NSLog(@"pathForXAxis: rect: %@ y: %f", NSStringFromCGRect(rect), y);
    BZPATH *path = [BZPATH bezierPath];
    BZPATH_MOVE_TO(path,CGPointMake(rect.origin.x,y));
    BZPATH_LINE_TO(path,CGPointMake(rect.origin.x+rect.size.width-1,y));
    return path;
}

- (CMKBezierPath *)pathForXAxisOverlayLabelForDataPoint:(ChartDataPoint *)dataPoint inViewRect:(CGRect)viewRect
{
    // point in data space
//    CGPoint dp = [self.series dataSpacePointForDataPoint:dataPoint];
    CGPoint dp = [self.series relativeDataSpacePointForDataPoint:dataPoint];
    // convert to point in view
    CGPoint p = [self mapPoint:dp toViewRect:viewRect];

//    NSString *string = [self formattedStringWithDate:[dataPoint.xValue valueAsDate]];
    NSString *string = [self.overlayDateFormatter stringFromDate:[dataPoint.xValue valueAsDate]];
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

- (CMKBezierPath *)pathForXAxisOverlayLabelOutlineForDataPoint:(ChartDataPoint *)dataPoint inViewRect:(CGRect)viewRect
{
    // point in data space
//    CGPoint dp = [self.series dataSpacePointForDataPoint:dataPoint];
    CGPoint dp = [self.series relativeDataSpacePointForDataPoint:dataPoint];
    // convert to point in view
    CGPoint p = [self mapPoint:dp toViewRect:viewRect];

//    NSString *string = [self formattedStringWithDate:dataPoint.xValue.valueAsDate];
    NSString *string = [self.overlayDateFormatter stringFromDate:[dataPoint.xValue valueAsDate]];
    CMKFont *font = [CMKFont fontWithName:self.model.labelsStyle.fontName size:self.model.labelsStyle.fontSize];
    CGRect labelRect = [self labelBoundsForString:string withFont:font atPoint:p inViewRect:viewRect];

    return [CMKBezierPath bezierPathWithRect:labelRect];
}


- (CGRect)labelBoundsForString:(NSString *)string withFont:(CMKFont *)font atPoint:(CGPoint)p inViewRect:(CGRect)viewRect
{
    BOOL inside = self.model.labelsPosition == CMKLabelsPositionInside;
    CGFloat labelMargin = self.model.labelMargin;
    CMKAxisPosition axisPos = [self effectiveAxisPosition];
    BOOL farOrigin = axisPos == CMKAxisPositionBottom;

    CGSize size = [string sizeWithAttributes:@{NSFontAttributeName:font}];
    CGFloat labelOffset = (inside ? (size.height+labelMargin) : -(size.height+labelMargin));
    if (farOrigin) labelOffset = -labelOffset;
    CGFloat labelOrigin = [self axisY];
    return CGRectMake(p.x-size.width*0.5f, labelOrigin+labelOffset, size.width, size.height);
}




// override
- (CMKBezierPath *)bezierPathForAxisGridlinesForSeries:(ChartSeries *)series major:(BOOL)major
{
    return [self bezierPathForAxisGridlinesForTimeSeries:series major:major];
}

- (CMKBezierPath *)bezierPathForAxisTickmarksForSeries:(ChartSeries *)series
{
    assert(0);      // obsolete
    return [self bezierPathForAxisTickmarksForTimeSeries:series];
}

- (CMKBezierPath *)bezierPathForAxisLabelsForSeries:(ChartSeries *)series
{
    return [self bezierPathForAxisLabelsForTimeSeries:series];
}

// draw the bezier path for the tickmarks, as defined by the supplied model.
// NOTE: this method is called once for each tickmarks model on the axis, so if there are different styles for top/bottom then a separate call is
// made with each model. The model's position property determines if/where the tickmarks are drawn.
- (CMKBezierPath *)tickmarksBezierPathForModel:(CMKTickMarksModel *)model
{
    CGRect axisBounds = [self.delegate axisViewBounds];
    CGSize size = model.size;
    // the model's position property determines drawing logic
    CMKTickmarksPosition pos = model.position;
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    
    [self enumerateCachedAxisGridlinesForTimeSeries:self.series gridlineFlags:(CMKGridlineFlagsMajor|CMKGridlineFlagsMinor) block:^(CMKAxisGridlineDescriptor *desc) {
        CGFloat hs = size.height * 0.5f;
        CMKAxisPosition axisPos = [self effectiveAxisPosition];
        BOOL bottom = axisPos == CMKAxisPositionBottom;

        CGFloat y0 = axisBounds.origin.y;
        CGFloat y1 = axisBounds.origin.y+axisBounds.size.height;
        CGFloat nearY = (bottom ? y1 : y0);
        CGFloat farY = (bottom ? y0 : y1);

        if (axisPos == CMKAxisPositionNone)
        {
            CGFloat axisY = [self axisY];
            // normal setting - axis is on a zero line somewhere between top and bottom
            CGPoint p0;
            if (pos & CMKTickmarksPositionNear)
            {
                // zero line is the near tickmark
                //NSLog(@"drawing path for near = zero");
                p0 = CGPointMake(desc.gridlineViewPointStart.x, axisY);
                [self addTickmarkToPath:path forModel:model atPosition:p0 height:hs near:YES];
            }
            if (pos & CMKTickmarksPositionFar)
            {
                //NSLog(@"drawing path for far = top");
                // far top
                p0 = CGPointMake(desc.gridlineViewPointStart.x, axisBounds.origin.y);
                [self addTickmarkToPath:path forModel:model atPosition:p0 height:hs near:YES];
                // far bottom
                //NSLog(@"drawing path for far = bottom");
                p0 = CGPointMake(desc.gridlineViewPointStart.x, axisBounds.origin.y+axisBounds.size.height);
                [self addTickmarkToPath:path forModel:model atPosition:p0 height:hs near:NO];
            }
        }
        else
        {
            // axis is at top or bottom
            if (pos & CMKTickmarksPositionNear)
            {
                // near
                CGPoint p0 = CGPointMake(desc.gridlineViewPointStart.x, nearY);
                [self addTickmarkToPath:path forModel:model atPosition:p0 height:hs near:!bottom];
            }
            if (pos & CMKTickmarksPositionFar)
            {
                // far
                CGPoint p0 = CGPointMake(desc.gridlineViewPointStart.x, farY);
                [self addTickmarkToPath:path forModel:model atPosition:p0 height:hs near:bottom];
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
        p0.y = p0.y + (near ? h : -h);
    }
    if (pos & CMKTickmarksPositionOutside)
    {
        p0.y = p0.y - (near ? h : -h);
    }
    CMKBezierPath *divPath = [CMKBezierPath bezierPath];
    [model addTickMarkToPath:path atPoint:p0];
    BZPATH_APPEND(path, divPath);
}


- (CMKBezierPath *)bezierPathForAxisGridlinesForTimeSeries:(ChartSeries *)series major:(BOOL)major
{
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    [self enumerateAxisGridlinesForTimeSeries:series major:major clearCache:!major block:^(CGPoint gridlineViewPointStart, CGPoint gridlineViewPointEnd, NSString *label, int index) {
        CMKBezierPath *divPath = [CMKBezierPath bezierPath];
        BZPATH_MOVE_TO(divPath, gridlineViewPointStart);
        BZPATH_LINE_TO(divPath, gridlineViewPointEnd);
        BZPATH_APPEND(path, divPath);
    }];
    return path;
}


- (CMKBezierPath *)bezierPathForAxisLabelsForTimeSeries:(ChartSeries *)series
{
    BOOL inside = self.model.labelsPosition == CMKLabelsPositionInside;
    CGFloat labelMargin = self.model.labelMargin;

    CMKAxisPosition axisPos = [self effectiveAxisPosition];
    BOOL farOrigin = axisPos == CMKAxisPositionBottom;
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    CGRect bounds = [self.delegate axisViewBounds];
    CMKFont *font = [CMKFont fontWithName:self.model.labelsStyle.fontName size:self.model.labelsStyle.fontSize];

    // common label text renderer
    XAxisGridlineDescEnumerationBlock block = ^(CMKAxisGridlineDescriptor *desc) {
        CGSize size = [desc.labelText sizeWithAttributes:@{NSFontAttributeName:font}];
        CGFloat labelOffset = (inside ? (size.height+labelMargin) : -(size.height+labelMargin));
        if (farOrigin) labelOffset = -labelOffset;
        CGFloat labelOrigin = [self axisY];
        CGFloat labelLeftX = desc.position.x-size.width*0.5f;
        CGFloat labelRightX = desc.position.x+size.width*0.5f;
        CGRect labelRect = CGRectMake(labelLeftX, labelOrigin+labelOffset, size.width, size.height);

        // do not overwrite any previously rendered adjacent labels
        CGFloat prevRight = desc.prev.labelBounds.origin.x + desc.prev.labelBounds.size.width;
        CGFloat nextLeft = (desc.next.labelBounds.origin.x > 0 ? desc.next.labelBounds.origin.x : FLT_MAX);

        if (labelLeftX >= prevRight+5.0f && labelRightX < nextLeft-5.0f)
        {
            desc.labelBounds = labelRect;
            if (!inside || CGRectContainsRect(bounds, labelRect))
            {
                CMKBezierPath *labelPath = [CMKBezierPath bezierPathFromString:desc.labelText withFont:font inRect:desc.labelBounds];
                [path appendPath:labelPath];
            }
        }
    };

    // draw major labels first, then minor ones if there's space
    [self enumerateCachedAxisGridlinesForTimeSeries:series gridlineFlags:(CMKGridlineFlagsMajor) block:block];
    [self enumerateCachedAxisGridlinesForTimeSeries:series gridlineFlags:(CMKGridlineFlagsMinor) block:block];

    return path;
}

#pragma mark - axis gridline enumerators

// Axis gridline enumerator for noncontiguous data
//
- (void)enumerateAxisGridlinesForTimeSeries:(ChartSeries *)series block:(XAxisEnumerationBlock)block
{
    [self enumerateAxisGridlinesForTimeSeries:series gridlineFlags:CMKGridlineFlagsMinor clearCache:NO block:block];
}

- (void)enumerateAxisGridlinesForTimeSeries:(ChartSeries *)series major:(BOOL)major clearCache:(BOOL)clearCache block:(XAxisEnumerationBlock)block
{
    [self enumerateAxisGridlinesForTimeSeries:series gridlineFlags:(major ? CMKGridlineFlagsMajor : CMKGridlineFlagsMinor) clearCache:clearCache block:block];
}


// Axis gridline enumerator for noncontiguous data
//
- (void)enumerateAxisGridlinesForTimeSeries:(ChartSeries *)series gridlineFlags:(CMKGridlineFlags)inflags clearCache:(BOOL)clearCache block:(XAxisEnumerationBlock)block
{
    if ((inflags & (CMKGridlineFlagsMajor|CMKGridlineFlagsMinor)) == (CMKGridlineFlagsMajor|CMKGridlineFlagsMinor))
    {
        NSLog(@"Timeseries gridline generator method cannot handle major and minor simulataneously - you should call once for each type");
        return;
    }

    if (!series || series.dataPoints.count == 0) return;
    
    // setup some common state...

    // for interday data, we need to ensure the contiguous data period is rounded to the nearest day, to cope with DST errors. We do that by subtracting one hour from interday periods and then rounding up.
    self.interdayDurationAdj = (series.isIntraday ? 0 : kSpecialPeriod1h);

    CGRect dataBounds = [self.delegate dataViewBounds];
    CGRect axisBounds = [self.delegate axisViewBounds];
    CGFloat axisPaddingFactor = dataBounds.size.width / axisBounds.size.width;
    
    // keep everything in seconds for accuracy and bcs scale could require it

    // Get the series range points from the current zoom level, or entire series if no zoom
    NSTimeInterval range = (self.zoomWindow ? self.zoomWindow->range : [series range]);
    self.axisRange = range / axisPaddingFactor;

    // calculate the division based on the data range
    // set smallestMinorDivision to the smallest minor division given the data resolution
    self.smallestMinorDivision = [self minMinorIntervalForSeries:series];
    // division is the estimated major division for the view range (not necessarily the actual major division that will be used by the enumerator)
    self.division = MAX([self divisionForTimePeriod:range], self.smallestMinorDivision);
    //NSLog(@"range hours %0.f days %0.f; self.division hours %0.f days %0.f", range/3600.0, range/3600.0/24.0, self.division/3600.0, self.division/3600.0/24.0);
    
    // paddingRange is the time range spanned by each end of the axis padding
    self.paddingRange = (self.axisRange-range)*0.5f;
    self.overlayDateFormatter = [self overlayDateFormatterForDivisionPeriod:self.division];

    if (inflags & CMKGridlineFlagsMajor)
    {
        [self enumerateAxisMajorGridlinesForTimeSeries:series gridlineFlags:inflags clearCache:clearCache block:block];
    }
    else
    {
        [self enumerateAxisMinorGridlinesForTimeSeries:series gridlineFlags:inflags clearCache:clearCache block:block];
    }
}


//***********************************************
#pragma mark - minor enumerator
//***********************************************

// Axis gridline enumerator for intraday noncontiguous data
//
- (void)enumerateAxisMinorGridlinesForTimeSeries:(ChartSeries *)series gridlineFlags:(CMKGridlineFlags)inflags clearCache:(BOOL)clearCache block:(XAxisEnumerationBlock)block
{
    assert(inflags == (inflags & CMKGridlineFlagsMinor));

    NSMutableArray *gridlineDescriptors;
    if (clearCache)
    {
        gridlineDescriptors = [NSMutableArray arrayWithCapacity:32];
    }
    else
    {
        gridlineDescriptors = [NSMutableArray arrayWithArray:self.gridlineDescriptors];
    }

//    CGRect dataBounds = [self.delegate dataViewBounds];
    CGRect axisBounds = [self.delegate axisViewBounds];

    // get the timestamp corresponding to the leftmost edge of the axis bounds, which is first datapoint time minus padding range
    NSDate *date0;
    if (self.zoomWindow)
    {
        date0 = [NSDate dateWithTimeIntervalSince1970:(self.zoomWindow->startValue - self.paddingRange)];
    }
    else
    {
        ChartTimeSeriesDataPoint *dataPoint0 = (ChartTimeSeriesDataPoint *)[series dataPointAtIndex:0];
        date0 = [[dataPoint0.xValue valueAsDate] dateByAddingTimeInterval:-self.paddingRange];
    }
    // get the timestamp for the first aligned division after date0
    //NSDate *div0Date = [self dateAfterDate:date0 moduloInterval:self.division];
    CMKAxisPosition axisPos = [self effectiveAxisPosition];
    BOOL bottomAxis = axisPos == CMKAxisPositionBottom;
    
    CGFloat gridlinesBottomBleed = (bottomAxis ? self.model.gridlinesNearBleed : self.model.gridlinesFarBleed);
    CGFloat gridlinesTopBleed = (bottomAxis ? self.model.gridlinesFarBleed : self.model.gridlinesNearBleed);

    // heuristically determine minor division using the estimated major division as the period
    NSTimeInterval minorDivision = MAX([self divisionForTimePeriod:self.division], self.smallestMinorDivision);
    self.dateFormatter = [self dateFormatterForDivisionPeriod:minorDivision];

    NSTimeInterval date0Epoch = [date0 timeIntervalSince1970];

    // axis-relative and absolute epoch times for each gridline
    __block NSTimeInterval tRel = -1, tAbs = -1;

    // iterate through the contiguous periods...
    __block int periodIndex = 0;
    __block NSTimeInterval prevEndEpoch = 0;
    [series enumerateContiguousPeriodsWithBlock:^(ChartContiguousPeriodDescriptor *desc, BOOL *stop)
    {
        //NSLog(@"enumerating period from %@, duration %0.f (%0.f hrs)", desc.startDate, desc.duration, (float)desc.duration/3600.0f);
        NSTimeInterval startEpoch = [desc.startDate timeIntervalSince1970];
        
        //NSLog(@"startEpoch %0.f nextStartEpoch %0.f desc.duration %0.f date0Epoch %0.f", startEpoch, desc.nextStartEpoch, desc.duration, date0Epoch);
        
        // decide what time is start of trading - this becomes "midnight" for inter-day gridlines
        NSTimeInterval t0 = [self interval:startEpoch roundedUp:NO toNearestDivision:3600*0.5];

        NSTimeInterval scaledDivision = minorDivision;
        NSTimeInterval periodRoundingDivision = (desc.duration >= kSpecialPeriod24h ? kSpecialPeriod24h : kSpecialPeriod1h * 0.5);
        NSTimeInterval period = [self interval:desc.duration-self.interdayDurationAdj roundedUp:YES toNearestDivision:periodRoundingDivision];

        // minor gridlines need rounded to division
        tAbs = [self interval:startEpoch roundedUp:NO toNearestDivision:scaledDivision];
        
        int ndiv = floor(period/scaledDivision);
        // if minor division is larger than contiguous data period, suppress minor divisions altogether
        if (ndiv == 0)
        {
            *stop = YES;
            return;
        }
        
        NSTimeInterval remainder = period - ndiv*scaledDivision;    // remainder division at end (e.g. 30 mins from 1600 to 1630 on LSE)
        NSTimeInterval overshootCorrection = (remainder > 0 ? scaledDivision-remainder : 0);  // period to subtract from axis time (tRel) after last division, in case it has overshot because of a nonzero remainder

        // after handling major gridline, move to first minor gridline. If there's a remainder, advance by that first for better layout
        tAbs += remainder;

        // we need start of day to be start of trading, not midnight (which will never appear on noncontiguous time series)
        if (scaledDivision >= 86400 && tAbs < t0)
        {
            tAbs = t0;
        }

        // tRel is based on start of first period, but increments relative to axis
        if (tRel < 0)
        {
            // first time, set tRel to tAbs
            tRel = tAbs;
        }
        else
        {
            // second period or later: tRel will likely have overshot by scaledDivision in last gridline "for" loop, so backtrack by a division, accounting for remainder we just advanced by.
            // &&& TODO - on interday charts, check remainder & overshoot correction still works for major gridlines (it makes no difference on intraday because residuals are zero, since scaledDivision == period when major is true)
            //NSLog(@"correcting tRel by overshootCorrection %0.f (major %d)", -overshootCorrection, (flags & CMKGridlineFlagsMajor));
            tRel -= overshootCorrection;
        }

        // this only runs for minor gridlines. scaledDivision is gridline period.
        NSTimeInterval t = 0.0;   // time relative to start of current period
        // draw gridlines, with extra divisions as required on either side for axis padding
        for (int i=0; t < period; i++, t+=scaledDivision, tRel+=scaledDivision, tAbs+=scaledDivision)
        {
        
            NSTimeInterval axisTime = tRel - date0Epoch;
            if (axisTime > self.axisRange)
            {
                //NSLog(@"out of range - ending");
                *stop = YES;
                return;
            }
        
            //NSLog(@"gridline index %d, tAbs %0.f = %@, tRel = %0.f", i, tAbs, [NSDate dateWithTimeIntervalSince1970:tAbs], tRel);

            // map time div to data bounds, and apply as offset to axis bounds
//            CGPoint p0;
//            if (self.zoomWindow)
//            {
//                p0 = [series mapPoint:CGPointMake(tRel, 0) toViewRect:dataBounds zoomWindow:*self.zoomWindow];
//            }
//            else
//            {
//                p0 = [series mapPoint:CGPointMake(tRel, 0) toViewRect:dataBounds];
//            }
//            p0.y = axisBounds.origin.y;
            CGPoint p0 = [self pointForTime:tRel inSeries:series bounds:axisBounds];
            
            // gridline runs on p0.x, between y bounds determined by axisBounds and bleed
            CGPoint pg0 = CGPointMake(p0.x, axisBounds.origin.y-gridlinesTopBleed);
            CGPoint pg1 = CGPointMake(p0.x, axisBounds.origin.y+axisBounds.size.height + gridlinesBottomBleed-1);

            if (CGRectContainsPoint(axisBounds, p0))
            {
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:tAbs];
                NSString *text = [self formattedStringWithDate:date major:NO];
                
                // create gridline descriptor
                CMKAxisGridlineDescriptor *desc = [[CMKAxisGridlineDescriptor alloc] init];
                desc.position = p0;
                desc.gridlineViewPointStart = pg0;
                desc.gridlineViewPointEnd = pg1;
                desc.epochTime = tAbs;
                desc.major = NO;
                desc.labelText = text;
                [gridlineDescriptors addObject:desc];
                
                // invoke caller's block
                block(pg0, pg1, text, i);
            }
        }
        
        prevEndEpoch = startEpoch + desc.duration;
        ++periodIndex;
    }];
    
    // now sort cache
    self.gridlineDescriptors = [self sortedCanonicalGridlineDescriptor:gridlineDescriptors];
}






//***********************************************
#pragma mark - major enumerator
//***********************************************


// Axis major gridline enumerator for noncontiguous data
//
- (void)enumerateAxisMajorGridlinesForTimeSeries:(ChartSeries *)series gridlineFlags:(CMKGridlineFlags)inflags clearCache:(BOOL)clearCache block:(XAxisEnumerationBlock)block
{
    assert(inflags == (inflags & CMKGridlineFlagsMajor));
    
    NSMutableArray *gridlineDescriptors;
    if (clearCache)
    {
        gridlineDescriptors = [NSMutableArray arrayWithCapacity:32];
    }
    else
    {
        gridlineDescriptors = [NSMutableArray arrayWithArray:self.gridlineDescriptors];
    }

    CGRect axisBounds = [self.delegate axisViewBounds];

    // get the timestamp corresponding to the leftmost edge of the axis bounds, which is first datapoint time minus padding range
    NSDate *date0;
    if (self.zoomWindow)
    {
        date0 = [NSDate dateWithTimeIntervalSince1970:(self.zoomWindow->startValue - self.paddingRange)];
    }
    else
    {
        ChartTimeSeriesDataPoint *dataPoint0 = (ChartTimeSeriesDataPoint *)[series dataPointAtIndex:0];
        date0 = [[dataPoint0.xValue valueAsDate] dateByAddingTimeInterval:-self.paddingRange];
    }

    // set the date format for the major gridlines
    self.majorDateFormatter = [self majorDateFormatterForDivisionPeriod:self.division];

    // all of this could be worked out when the model is set...
    CMKAxisPosition axisPos = [self effectiveAxisPosition];
    BOOL bottomAxis = axisPos == CMKAxisPositionBottom;
    CGFloat gridlinesBottomBleed = (bottomAxis ? self.model.gridlinesNearBleed : self.model.gridlinesFarBleed);
    CGFloat gridlinesTopBleed = (bottomAxis ? self.model.gridlinesFarBleed : self.model.gridlinesNearBleed);

    //NSTimeInterval date0Epoch = [date0 timeIntervalSince1970];

    // grid requiring alignment to month, quarter or year requires extra work to align to specific calendar boundaries
    // (30 days won't cut it as month alignment)
    CMKGridlineAlignment alignmentMode = CMKGridlineAlignmentToDivision;
    if (self.division >= kSpecialPeriod30d)
    {
        // need to align to start of month, quarter or year
        if (self.division >= kSpecialPeriod12m)
        {
            alignmentMode = CMKGridlineAlignmentToYear;
        }
        else if (self.division >= kSpecialPeriod3m)
        {
            alignmentMode = CMKGridlineAlignmentToQuarter;
        }
        else
        {
            alignmentMode = CMKGridlineAlignmentToCalendarMonth;
        }
    }

    // axis-relative and absolute epoch times for each gridline
    __block NSTimeInterval tRel = -1, tAbs = -1;

    // iterate through the contiguous periods...
    __block int periodIndex = 0;
    __block NSTimeInterval prevEndEpoch = 0;

//    __block NSTimeInterval scaledDivision = MAX(period, self.division); // &&& needs advance knowledge - perhaps calc mean (or modal) period in series processGaps method?
    __block NSTimeInterval scaledDivision = self.division;  // &&& for now do this
    __block NSTimeInterval tNextMajor = -1;  // absolute time for next major gridline

    [series enumerateContiguousPeriodsWithBlock:^(ChartContiguousPeriodDescriptor *desc, BOOL *stop)
    {
        //NSLog(@"enumerating period from %@, duration %0.f (%0.f hrs)", desc.startDate, desc.duration, (float)desc.duration/3600.0f);
        
        // establish contiguous period start time. If intraday, this will be start of trading, else it will be midnight for interday
        NSTimeInterval startEpoch = [desc.startDate timeIntervalSince1970];
        NSTimeInterval t0;
        if (series.isIntraday)
        {
            t0 = [self interval:startEpoch roundedUp:NO toNearestDivision:3600*0.5];
        }
        else
        {
            t0 = startEpoch;
        }
        
        //NSLog(@"startEpoch %0.f nextStartEpoch %0.f desc.duration %0.f date0Epoch %0.f", startEpoch, desc.nextStartEpoch, desc.duration, date0Epoch);

        NSTimeInterval periodRoundingDivision = (desc.duration >= kSpecialPeriod24h ? kSpecialPeriod24h : kSpecialPeriod1h * 0.5);
        NSTimeInterval period = [self interval:desc.duration-self.interdayDurationAdj roundedUp:YES toNearestDivision:periodRoundingDivision];

        // work out start for major gridlines
        if (tNextMajor < 0)
        {
            // this works fine for setting next major
            switch (alignmentMode)
            {
                case CMKGridlineAlignmentToDivision:
                    // for major grid aligned to 5 day weeks, can just round to next nearest division
                    tNextMajor = t0;//[self interval:t0 roundedUp:YES toNearestDivision:scaledDivision];
                    break;
                case CMKGridlineAlignmentToCalendarMonth:
                    tNextMajor = [[desc.startDate firstDayOfNextMonth] timeIntervalSince1970];
                    break;
                case CMKGridlineAlignmentToQuarter:
                    tNextMajor = [[[desc.startDate firstDayOfMonth] dateByAddingMonths:3] timeIntervalSince1970];
                    break;
                case CMKGridlineAlignmentToYear:
                    tNextMajor = [[[desc.startDate firstDayOfMonth] dateByAddingMonths:12] timeIntervalSince1970];
                    break;
            }
        }
        else if (alignmentMode == CMKGridlineAlignmentToDivision)
        {
            tNextMajor = t0;
        }
        

        // major gridlines just need to be aligned to start of trading or midnight
        tAbs = t0;

        // tRel is based on start of first period, but increments relative to axis
        if (tRel < 0)
        {
            // first time, set tRel to tAbs
            tRel = tAbs;
        }
        
        NSTimeInterval tMajor = -1;
        NSTimeInterval tMajorOffset = 0;

        if (tNextMajor >= t0 && tNextMajor < t0+period)
        {
            // next major division will be within this period
            tMajor = tNextMajor;
            tMajorOffset = tMajor - t0; // the relative offset of tMajor within the period
        }
        else if (t0 > tNextMajor)
        {
            // this period has gapped beyond actual major position
            tMajor = tNextMajor;
            tMajorOffset = 0;
        }

        //NSLog(@"t0 %0.f %@, tMajor %0.f %@, tMajorOffset %0.f tNextMajor %0.f %@", t0, [NSDate dateWithTimeIntervalSince1970:t0], tMajor, [NSDate dateWithTimeIntervalSince1970:tMajor], tMajorOffset, tNextMajor, [NSDate dateWithTimeIntervalSince1970:tNextMajor]);
        if (tMajor >= 0)
        {
            NSTimeInterval tMajorRel = tRel + tMajorOffset;
            
            //NSLog(@"Aligned for major gridline: tAbs %0.f", tAbs);
            CGPoint p0 = [self pointForTime:tMajorRel inSeries:series bounds:axisBounds];
            
            // gridline runs on p0.x, between y bounds determined by axisBounds and bleed
            CGPoint pg0 = CGPointMake(p0.x, axisBounds.origin.y-gridlinesTopBleed);
            CGPoint pg1 = CGPointMake(p0.x, axisBounds.origin.y+axisBounds.size.height + gridlinesBottomBleed-1);

            if (CGRectContainsPoint(axisBounds, p0))
            {
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:tMajor];
                NSString *text = [self formattedStringWithDate:date major:YES];
                
                // create gridline descriptor
                CMKAxisGridlineDescriptor *gridlineDesc = [[CMKAxisGridlineDescriptor alloc] init];
                gridlineDesc.position = p0;
                gridlineDesc.gridlineViewPointStart = pg0;
                gridlineDesc.gridlineViewPointEnd = pg1;
                gridlineDesc.epochTime = tMajor;
                gridlineDesc.major = YES;
                gridlineDesc.labelText = text;
                [gridlineDescriptors addObject:gridlineDesc];
                //NSLog(@"created gridline desc: epochTime %f labelText %@ major %d", gridlineDesc.epochTime, gridlineDesc.labelText, gridlineDesc.major);
            
                // invoke caller's block
                block(pg0, pg1, text, 0);
            }

            NSDate *majorDate = [NSDate dateWithTimeIntervalSince1970:tMajor];
            switch (alignmentMode)
            {
                case CMKGridlineAlignmentToDivision:
                    // for major grid aligned to 5 day weeks, can just round to next nearest division
                    tNextMajor = tMajor + scaledDivision;
                    // this may be ignored and start of next period may be used next time
                    break;
                case CMKGridlineAlignmentToCalendarMonth:
                    tNextMajor = [[majorDate dateByAddingMonths:1] timeIntervalSince1970];
                    break;
                case CMKGridlineAlignmentToQuarter:
                    tNextMajor = [[[majorDate firstDayOfMonth] dateByAddingMonths:3] timeIntervalSince1970];
                    break;
                case CMKGridlineAlignmentToYear:
                    tNextMajor = [[[majorDate firstDayOfMonth] dateByAddingMonths:12] timeIntervalSince1970];
                    break;
            }

        }

        // we need start of day to be start of trading, not midnight (which will never appear on noncontiguous time series)
        if (scaledDivision >= 86400 && tAbs < t0)
        {
            tAbs = t0;
        }

        // add elapsed period to relative time
        tRel += period;
        
        prevEndEpoch = startEpoch + desc.duration;
        ++periodIndex;
    }];
    
    // now sort cache
    self.gridlineDescriptors = [self sortedCanonicalGridlineDescriptor:gridlineDescriptors];
    //NSLog(@"sorted gridlines: count %ld", self.gridlineDescriptors.count);
}







#pragma mark - cached enumerators

// Cached axis gridline enumerator - only call this when
//
- (void)enumerateCachedAxisGridlinesForTimeSeries:(ChartSeries *)series gridlineFlags:(CMKGridlineFlags)gridlineFlags block:(XAxisGridlineDescEnumerationBlock)block
{
    if (self.gridlineDescriptors.count > 0)
    {
        int i = 0;
        for (CMKAxisGridlineDescriptor *desc in self.gridlineDescriptors)
        {
            CMKGridlineFlags flags = (desc.major ? CMKGridlineFlagsMajor : CMKGridlineFlagsMinor);
            if (gridlineFlags & flags)
            {
                //NSLog(@"enumerating cached gridline epochTime %f labelText %@ major %d", desc.epochTime, desc.labelText, desc.major);
                block(desc);
            }
            ++i;
        }
    }
    else
    {
        NSLog(@"Warning: called enumerateCachedAxisGridlinesForTimeSeries:gridlineFlags:block: but no cached gridlines found");
    }
}



#pragma mark - enumerator helpers


- (NSArray *)sortedCanonicalGridlineDescriptor:(NSArray *)gridlineDescriptors
{
    // now sort cache
    NSSortDescriptor *sortDesc1 = [NSSortDescriptor sortDescriptorWithKey:@"epochTime" ascending:YES];
    NSSortDescriptor *sortDesc2 = [NSSortDescriptor sortDescriptorWithKey:@"major" ascending:NO];
//    NSMutableArray *sortedArray = [gridlineDescriptors sortedArrayUsingDescriptors:@[sortDesc1, sortDesc2]];
    NSMutableArray *sortedArray = [NSMutableArray arrayWithCapacity:gridlineDescriptors.count];
    NSTimeInterval lastTime = -1;
    CMKAxisGridlineDescriptor *prev = nil;
    for (CMKAxisGridlineDescriptor *desc in [gridlineDescriptors sortedArrayUsingDescriptors:@[sortDesc1, sortDesc2]])
    {
        // discard gridlines with duplicate time
        if (desc.epochTime > lastTime)
        {
            [sortedArray addObject:desc];
            lastTime = desc.epochTime;
            prev.next = desc;
            desc.prev = prev;
            
            // store current desc as prev for next time as it's good
            prev = desc;
        }
//        else
//        {
//            NSLog(@"discarding duplicate desc %@");
//        }
    }
    return sortedArray;
}

- (NSTimeInterval)minMinorIntervalForSeries:(ChartSeries *)series
{
    if (series.isIntraday)
    {
        return kSpecialPeriod5min;
    }
    else
    {
        return kSpecialPeriod24h;
    }
}


- (CGPoint)pointForTime:(NSTimeInterval)time inSeries:(ChartSeries *)series bounds:(CGRect)bounds
{
    CGPoint p0;
    if (self.zoomWindow)
    {
        p0 = [series mapPoint:CGPointMake(time, 0) toViewRect:bounds zoomWindow:*self.zoomWindow];
    }
    else
    {
        p0 = [series mapPoint:CGPointMake(time, 0) toViewRect:bounds];
    }
    p0.y = bounds.origin.y;
    return p0;
}


// round an interval up or down to the nearest division
//
- (NSTimeInterval)interval:(NSTimeInterval)interval roundedUp:(BOOL)up toNearestDivision:(NSTimeInterval)division
{
    NSTimeInterval rem = fmod(interval, division);
    return interval + (up ? division-rem : -rem);
}

#pragma mark - gridline division heuristics

// date formatter for minor gridlines
- (NSDateFormatter *)dateFormatterForDivisionPeriod:(NSTimeInterval)period
{
    // period is division period, not chart period
    NSString *template = @"ddMMMHHmmss";
    if (period < kSpecialPeriod1min)
    {
        template = @"HHmmss";
    }
    else if (period <= kSpecialPeriod1h)
    {
        template = @"HHmm";
    }
    else if (period <= kSpecialPeriod4h)
    {
        template = @"HHmm";
    }
    else if (period < kSpecialPeriod24h)
    {
        template = @"HHmm";
    }
    else if (period < kSpecialPeriod5d)
    {
        template = @"ddMMM";
    }
    else if (period < kSpecialPeriod30d)
    {
        template = @"ddMMM";
    }
    else
    {
        template = @"MMMyyyy";
    }

    // optimization - only allocate new date formatter when template changes
    if (![template isEqualToString:_dateFormatterTemplate])
    {
        _dateFormatterTemplate = template;
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:[NSLocale currentLocale]];
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:formatString];
        [_dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    return _dateFormatter;
}

// date formatter for major gridlines
- (NSDateFormatter *)majorDateFormatterForDivisionPeriod:(NSTimeInterval)period
{
    // period is division period, not chart period
    NSString *template = @"ddMMMHHmmss";
    if (period <= kSpecialPeriod24h)
    {
        template = @"ddMMMyyyy";
    }
    else if (period < kSpecialPeriod30d)
    {
        template = @"ddMMM";
    }
    else
    {
        template = @"MMMyyyy";
    }

    // optimization - only allocate new date formatter when template changes
    if (![template isEqualToString:_majorDateFormatterTemplate])
    {
        _majorDateFormatterTemplate = template;
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:[NSLocale currentLocale]];
        _majorDateFormatter = [[NSDateFormatter alloc] init];
        [_majorDateFormatter setDateFormat:formatString];
        [_majorDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    return _majorDateFormatter;
}


- (NSDateFormatter *)overlayDateFormatterForDivisionPeriod:(NSTimeInterval)period
{
    // period is division period, not chart period
    NSString *template = @"ddMMMHHmmss";
    if (period < kSpecialPeriod24h)
    {
        template = @"dd MMM HHmm";
    }
    else
    {
        template = @"ddMMMyyyy";
    }

    // optimization - only allocate new date formatter when template changes
    if (![template isEqualToString:_overlayDateFormatterTemplate])
    {
        _overlayDateFormatterTemplate = template;
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:[NSLocale currentLocale]];
        _overlayDateFormatter = [[NSDateFormatter alloc] init];
        [_overlayDateFormatter setDateFormat:formatString];
        [_overlayDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    return _overlayDateFormatter;
}


- (NSTimeInterval)divisionForTimePeriod:(NSTimeInterval)period
{
    // period is chart period
    // NOTE: this is relative, not absolute, i.e. the number of seconds in the data on the chart, not the absolute time span
    NSTimeInterval division;
    if (period < kSpecialPeriod1min)
    {
        division = 15;
    }
    else if (period <= kSpecialPeriod5min)
    {
        division = kSpecialPeriod1min;
    }
    else if (period <= kSpecialPeriod15min)
    {
        division = kSpecialPeriod5min;
    }
    else if (period <= kSpecialPeriod1h)
    {
        division = kSpecialPeriod15min;
    }
    else if (period <= kSpecialPeriod4h)
    {
        division = kSpecialPeriod1h;
    }
    else if (period <= kSpecialPeriod1h*12)
    {
        division = 2*kSpecialPeriod1h;
    }
    else if (period <= kSpecialPeriod24h)
    {
        division = 3*kSpecialPeriod1h;
    }
    else if (period <= kSpecialPeriod2d)
    {
        division = 4*kSpecialPeriod1h;
    }
    else if (period <= kSpecialPeriod5d)
    {
        division = 6*kSpecialPeriod1h;
    }
    else if (period <= kSpecialPeriod7d)
    {
        division = kSpecialPeriod24h;
    }
    else if (period <= kSpecialPeriod30d)
    {
        division = kSpecialPeriod5d;
    }
    else if (period <= kSpecialPeriod3m)
    {
        division = kSpecialPeriod30d;
    }
    else if (period <= kSpecialPeriod6m)
    {
        division = kSpecialPeriod30d;
    }
    else if (period <= kSpecialPeriod12m)
    {
        division = kSpecialPeriod3m;
    }
    else
    {
        division = kSpecialPeriod12m;
    }
    return division;
}

- (BOOL)period:(CGFloat)period isWithinPercent:(CGFloat)percent ofTarget:(CGFloat)target
{
    return (period >= target*(100-percent)*.01f) && (period <= target*(100+percent)*.01f);
}

//- (NSTimeInterval)dateRangeForSeries:(ChartSeries *)series
//{
//    ChartTimeSeriesDataPoint *dataPoint0 = (ChartTimeSeriesDataPoint *)[series dataPointAtIndex:0];
//    ChartTimeSeriesDataPoint *dataPoint1 = (ChartTimeSeriesDataPoint *)[series dataPointAtIndex:series.count-1];
//    return [[dataPoint1.xValue valueAsDate] timeIntervalSinceDate:[dataPoint0.xValue valueAsDate]];
//}

- (NSDate *)dateAfterDate:(NSDate *)date moduloInterval:(NSTimeInterval)interval
{
    NSTimeInterval epoch = [date timeIntervalSince1970];
//    float remainder = fmod(epoch, interval);
//    float tdiv0 = interval-remainder;
    float tdiv0 = [self intervalAfterDate:date moduloInterval:interval];
    NSDate *div0 = [NSDate dateWithTimeIntervalSince1970:epoch+tdiv0];
    return div0;
}

- (NSTimeInterval)intervalAfterDate:(NSDate *)date moduloInterval:(NSTimeInterval)interval
{
    NSTimeInterval epoch = [date timeIntervalSince1970];
    float remainder = fmod(epoch, interval);
    return interval-remainder;
}

#pragma mark - specialised label formatting for timeseries

- (NSString *)formattedStringWithDate:(NSDate *)date major:(BOOL)major
{
    if (major)
    {
        return [self.majorDateFormatter stringFromDate:date];
    }
    else
    {
        return [self.dateFormatter stringFromDate:date];
    }
}


@end
