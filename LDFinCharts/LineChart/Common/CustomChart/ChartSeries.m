//
//  ChartSeries.m
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 26/02/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "ChartSeries.h"
#import "CMKChartSeriesModel.h"
#import "CMKBezierPath+Smoothing.h"
#import "CMKBezierPath+CMKExtensions.h"
#import "CMKColor+CMKExtensions.h"
#import "ChartXAxis.h"
#import "ChartYAxis.h"
#import "timeseries.h"
#import "ChartContiguousPeriodDescriptor.h"

static const NSTimeInterval kTimeInterval1Hour = 3600.0;
static const NSTimeInterval kTimeInterval1Day = 24 * kTimeInterval1Hour;
static const NSTimeInterval kTimeInterval5Days = 5 * kTimeInterval1Day;
static const NSTimeInterval kTimeIntervalTradingTime = 8.5 * kTimeInterval1Hour; // approx, depending on exch.

@interface ChartSeries()
{
    CGFloat _maxY, _minY;
    NSDate *_minTimeX, *_maxTimeX;
}
@property (nonatomic, strong) NSArray *contiguousPeriods;

@end

@implementation ChartSeries

- (id)init
{
    self = [super init];
    if (self)
    {
        self.dataPoints = [NSMutableArray arrayWithCapacity:1024];
        [self invalidate];
    }
    return self;
}

- (void)setModel:(CMKChartSeriesModel *)model
{
    _model = model;
}

- (void)invalidate
{
    _maxY = -INFINITY;
    _minY = INFINITY;
    _minTimeX = [NSDate distantFuture];
    _maxTimeX = [NSDate distantPast];
}

- (NSInteger)count
{
    return [self.dataPoints count];
}

- (ChartDataPoint *)dataPointAtIndex:(NSInteger)index
{
    if (index >= 0 && index < self.dataPoints.count)
    {
        return self.dataPoints[index];
    }
    else
    {
        return nil;
    }
}

- (void)addDataPoint:(ChartDataPoint *)dataPoint
{
    [self.dataPoints addObject:dataPoint];
}

- (void)addSeries:(ChartSeries *)series
{
    for (ChartDataPoint *dataPoint in series.dataPoints)
    {
        [self addDataPoint:dataPoint];
    }
}


- (CGFloat)maxY
{
    if (_maxY <= -INFINITY)
    {
        CGFloat max = -INFINITY;
        for (ChartDataPoint *dataPoint in self.dataPoints)
        {
            CGFloat val = [[dataPoint.yValue valueAsNumber] floatValue];
            if (val > max)
            {
                max = val;
            }
        }
        _maxY = max;
    }
    return _maxY;
}


- (CGFloat)minY
{
    if (_minY >= INFINITY)
    {
        CGFloat min = INFINITY;
        int i=0;
        for (ChartDataPoint *dataPoint in self.dataPoints)
        {
            CGFloat val = [[dataPoint.yValue valueAsNumber] floatValue];
            if (val < min)
            {
                min = val;
            }
//            if (min <= 0)
//            {
//                NSLog(@"i %d, min <= 0", i);
//            }
            ++i;
        }
        _minY = min;
    }
    return _minY;
}

- (NSDate *)minTimeX
{
    if (_minTimeX >= [NSDate distantFuture])
    {
        NSDate *min = [NSDate distantFuture];
        for (ChartDataPoint *dataPoint in self.dataPoints)
        {
            NSDate *date = [dataPoint.xValue valueAsDate];
            if ([min compare:date] == NSOrderedDescending)
            {
                min = date;
            }
        }
        _minTimeX = min;
    }
    return _minTimeX;
}

- (NSDate *)maxTimeX
{
    if (_maxTimeX <= [NSDate distantPast])
    {
        NSDate *max = [NSDate distantPast];
        for (ChartDataPoint *dataPoint in self.dataPoints)
        {
            NSDate *date = [dataPoint.xValue valueAsDate];
            if ([max compare:date] == NSOrderedAscending)
            {
                max = date;
            }
        }
        _maxTimeX = max;
    }
    return _maxTimeX;
}

- (NSDate *)minTimeXRelative
{
    if (_minTimeX >= [NSDate distantFuture])
    {
        NSDate *min = [NSDate distantFuture];
        for (ChartDataPoint *dataPoint in self.dataPoints)
        {
            NSDate *date = [dataPoint.xValueRelative valueAsDate];
            if ([min compare:date] == NSOrderedDescending)
            {
                min = date;
            }
        }
        _minTimeX = min;
    }
    return _minTimeX;
}

- (NSDate *)maxTimeXRelative
{
    if (_maxTimeX <= [NSDate distantPast])
    {
        NSDate *max = [NSDate distantPast];
        for (ChartDataPoint *dataPoint in self.dataPoints)
        {
            NSDate *date = [dataPoint.xValueRelative valueAsDate];
            if ([max compare:date] == NSOrderedAscending)
            {
                max = date;
            }
        }
        _maxTimeX = max;
    }
    return _maxTimeX;
}


- (NSTimeInterval)dateRange
{
    ChartTimeSeriesDataPoint *dataPoint0 = (ChartTimeSeriesDataPoint *)[self dataPointAtIndex:0];
    ChartTimeSeriesDataPoint *dataPoint1 = (ChartTimeSeriesDataPoint *)[self dataPointAtIndex:self.count-1];
    return [[dataPoint1.xValue valueAsDate] timeIntervalSinceDate:[dataPoint0.xValue valueAsDate]];
}

- (NSTimeInterval)dateRangeRelative
{
    ChartTimeSeriesDataPoint *dataPoint0 = (ChartTimeSeriesDataPoint *)[self dataPointAtIndex:0];
    ChartTimeSeriesDataPoint *dataPoint1 = (ChartTimeSeriesDataPoint *)[self dataPointAtIndex:self.count-1];
    return [[dataPoint1.xValueRelative valueAsDate] timeIntervalSinceDate:[dataPoint0.xValueRelative valueAsDate]];
}

- (double)range
{
    // &&& TODO non-date
    if (self.derivedFrom)
    {
        return [self.derivedFrom dateRangeRelative];
    }
    else
    {
        return [self dateRangeRelative];
    }
}


#pragma mark - series/view mapping

- (CMKZoomWindow)zoomWindowForZoomLevel:(CGFloat)zoomLevel centre:(double)centre
{
    return [self zoomWindowForZoomLevel:zoomLevel centre:centre withIndices:YES];
}

- (CMKZoomWindow)zoomWindowForZoomLevel:(CGFloat)zoomLevel centre:(double)centre withIndices:(BOOL)findIndices
{
    assert(zoomLevel > 0);

    // first get the relative axis values around the centre
    double range = [self range] / zoomLevel;
    double startValueRelative = centre - (range * 0.5);
    double endValueRelative = centre + (range * 0.5);
    // seriesMinX and seriesMaxX define the min and max values in the entire series
//    NSTimeInterval seriesMinX = [self.minTimeX timeIntervalSince1970];
//    NSTimeInterval seriesMaxX = [self.maxTimeX timeIntervalSince1970];
    NSTimeInterval seriesMinX = [self.minTimeXRelative timeIntervalSince1970];
    NSTimeInterval seriesMaxX = [self.maxTimeXRelative timeIntervalSince1970];

    // convert relative values to absolute axis values
    double startValueAbs = seriesMinX+startValueRelative;
    double endValueAbs = seriesMinX+endValueRelative;

    // clamp against extremes of series
    CGFloat clampMin = 0;
    if (startValueAbs < seriesMinX)
    {
        clampMin = seriesMinX - startValueAbs;
        startValueAbs = seriesMinX;
        endValueAbs = startValueAbs+range;
        //NSLog(@"clamp min %0.f", clampMin);
    }
    CGFloat clampMax = 0;
    if (endValueAbs > seriesMaxX)
    {
        clampMax = endValueAbs - seriesMaxX;
        endValueAbs = seriesMaxX;
        startValueAbs = endValueAbs-range;
        //NSLog(@"clamp max %0.f", clampMax);
    }

    int startIndex=0, endIndex=[self count]-1;
    if (findIndices)
    {
        // work out datapoint indices, and extend one point each side of window (with clamping at limits)
//        startIndex = [self dataPointIndexForStartXValue:startValueAbs] - 1;
        startIndex = [self dataPointIndexForStartXValueRelative:startValueAbs] - 1;
        if (startIndex < 0) startIndex = 0;
//        endIndex = [self dataPointIndexForEndXValue:endValueAbs startIndex:startIndex] + 1;
        endIndex = [self dataPointIndexForEndXValueRelative:endValueAbs startIndex:startIndex] + 1;
        if (endIndex >= [self.dataPoints count]) endIndex = (int)[self.dataPoints count]-1;
    }
    // create the zoom window struct
    CMKZoomWindow window = { .zoomLevel = zoomLevel, .startValue = startValueAbs, .endValue = endValueAbs, .range = range, .spanPoints = endIndex-startIndex, .startIndex = startIndex, .endIndex = endIndex,
                            .clampMin = clampMin, .clampMax = clampMax };
    //NSLog(@"zoomWindow level %0.3f startValue %f endValue %f range %f spanPoints %d startIndex %d endIndex %d", window.zoomLevel, window.startValue, window.endValue, window.range, window.spanPoints, window.startIndex, window.endIndex);
    return window;
}


- (int)nearestDataPointIndexForXValue:(double)xValue
{
    ChartDataPoint *dataPoint0 = self.dataPoints[0];
    double prevValue = [dataPoint0.xValue valueAsEpochTime];
    if (xValue < prevValue) return -1;
    if (xValue == prevValue) return 0;
    
    for (int index=0; index < [self.dataPoints count]; index++)
    {
        ChartDataPoint *dataPoint = self.dataPoints[index];
        double value = [dataPoint.xValue valueAsEpochTime];
        if (xValue > prevValue && xValue <= value)
        {
            return index;
        }
        prevValue = value;
    }
    return -1;
}


- (int)dataPointIndexForStartXValue:(double)xValue
{
    for (int index=0; index < [self.dataPoints count]; index++)
    {
        ChartDataPoint *dataPoint = self.dataPoints[index];
        double value = [dataPoint.xValue valueAsEpochTime];
        if (value >= xValue) return index;
    }
    return -1;
}

- (int)dataPointIndexForEndXValue:(double)xValue startIndex:(int)startIndex
{
    for (int index=startIndex; index < [self.dataPoints count]; index++)
    {
        ChartDataPoint *dataPoint = self.dataPoints[index];
        double value = [dataPoint.xValue valueAsEpochTime];
        if (value >= xValue) return index;
    }
    return -1;
}

- (int)dataPointIndexForStartXValueRelative:(double)xValue
{
    for (int index=0; index < [self.dataPoints count]; index++)
    {
        ChartDataPoint *dataPoint = self.dataPoints[index];
        double value = [dataPoint.xValueRelative valueAsEpochTime];
        if (value >= xValue) return index;
    }
    return -1;
}

- (int)dataPointIndexForEndXValueRelative:(double)xValue startIndex:(int)startIndex
{
    for (int index=startIndex; index < [self.dataPoints count]; index++)
    {
        ChartDataPoint *dataPoint = self.dataPoints[index];
        double value = [dataPoint.xValueRelative valueAsEpochTime];
        if (value >= xValue) return index;
    }
    return -1;
}

- (int)dataPointIndexForDateValue:(NSDate *)desiredDate
{
    // TODO: this could be made much more efficient
    for (int index=0; index < [self.dataPoints count]; index++)
    {
        ChartDataPoint *dataPoint = self.dataPoints[index];
        NSDate *date = [dataPoint.xValue valueAsDate];
        if (desiredDate >= date) return index;
    }
    return -1;
}

- (ChartDataPoint * _Nullable)dataPointForDateValue:(NSDate *)date
{
    int index = [self dataPointIndexForDateValue:date];
    if (index >= 0 && index < self.dataPoints.count)
    {
        return self.dataPoints[index];
    }
    return nil;
}



#pragma mark - Map data space to view coords

- (CGPoint)mapPoint:(CGPoint)point toViewRect:(CGRect)rect
{
    CMKZoomWindow zoomWindow = [self zoomWindowForZoomLevel:1.0 centre:0];
    return [self mapPoint:point toViewRect:rect zoomWindow:zoomWindow];
}

- (CGPoint)mapPoint:(CGPoint)point toViewRect:(CGRect)rect zoomWindow:(CMKZoomWindow)zoomWindow
{
    CGFloat viewRangeX = rect.size.width;
    CGFloat viewRangeY = rect.size.height;
    
    NSTimeInterval minX = (NSTimeInterval)zoomWindow.startValue;

    // calculate the range. If the series is linked to an axis, use the whole axis' range in order to scale correctly for all series on the axis
    CGFloat minY = (self.yAxis ? self.yAxis.series.minY : self.minY);
    CGFloat maxY = (self.yAxis ? self.yAxis.series.maxY : self.maxY);
    CGFloat yRange = maxY-minY;
    if (yRange == 0)
    {
        // deal with flat data when yRange is zero and we get maths errors (NaNs). Expand the min/max thresholds to compensate
        //NSLog(@"Warning: yRange is zero - modifying to prevent maths errors");
        minY = minY * 0.5f;
        maxY += maxY - minY;
        yRange = maxY-minY;
    }

    CGFloat yScale = viewRangeY / yRange;
    CGFloat y = (rect.origin.y+rect.size.height) - ((point.y-minY) * yScale);

    CGFloat xScale = viewRangeX / zoomWindow.range;
    CGFloat x = rect.origin.x + ((point.x-minX) * xScale);

//    if (y < rect.origin.y)
//    {
//        NSLog(@"Warning: mapPoint point (%0.f,%0.f) maps to y %0.f which is below viewRect bounds (%0.f,%0.f,%0.f,%0.f)",
//            point.x, point.y, y, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
//    }

    // if NaNs make it into a Bezier path they will cause CoreGraphics to complain so catch them at source
    if (isnan(x))
    {
        NSLog(@"Error: x is NAN");
        assert(!isnan(x));
    }
    if (isnan(y))
    {
        NSLog(@"Error: y is NAN");
        assert(!isnan(y));
    }

    //NSLog(@"mapped point: (%0.3f,%0.3f) to (%0.3f,%0.3f)", point.x, point.y, x, y);

    return CGPointMake(x, y);
}

#pragma mark Map view coords to data space

- (CGFloat)mapViewX:(CGFloat)viewX fromViewRect:(CGRect)rect
{
    CMKZoomWindow zoomWindow = [self zoomWindowForZoomLevel:1.0 centre:0];
    return [self mapViewX:viewX fromViewRect:rect zoomWindow:zoomWindow];
}

- (CGFloat)mapViewX:(CGFloat)viewX fromViewRect:(CGRect)rect zoomWindow:(CMKZoomWindow)zoomWindow
{
    CGFloat viewRangeX = rect.size.width;
    CGFloat viewRangeY = rect.size.height;

    NSTimeInterval minX = (NSTimeInterval)zoomWindow.startValue;
    CGFloat xScale = viewRangeX / zoomWindow.range;

    CGFloat x = ((viewX - rect.origin.x) / xScale) + minX;
    // x is in data space, e.g. if this is a time series, x is now the epoch date for the viewX point
    return x;
}



// return a CGPoint in data space
- (CGPoint)dataSpacePointForDataPoint:(ChartDataPoint *)dataPoint
{
    CGFloat yval = [[dataPoint.yValue valueAsNumber] floatValue];
    // time axis in seconds
    // &&& TODO: make this more generic
//    CGFloat xval = (CGFloat)[[dataPoint.xValue valueAsDate] timeIntervalSince1970];
    CGFloat xval = (CGFloat)[dataPoint.xValue valueAsEpochTime];
    return CGPointMake(xval, yval);
}


// return a CGPoint in data space
- (CGPoint)relativeDataSpacePointForDataPoint:(ChartDataPoint *)dataPoint
{
    CGFloat yval = [[dataPoint.yValue valueAsNumber] floatValue];
    // time axis in seconds
    CGFloat xval = (CGFloat)[dataPoint.xValueRelative valueAsEpochTime];
    return CGPointMake(xval, yval);
}

/*
- (CGPoint)sampleWidthForViewRect:(CGRect)rect zoomWindow:(CMKZoomWindow)zoomWindow
{
    CGFloat viewRangeX = rect.size.width;
    NSTimeInterval minX = (NSTimeInterval)zoomWindow.startValue;
//
//    // calculate the range. If the series is linked to an axis, use the whole axis' range in order to scale correctly for all series on the axis
//    CGFloat minY = (self.yAxis ? self.yAxis.series.minY : self.minY);
//    CGFloat maxY = (self.yAxis ? self.yAxis.series.maxY : self.maxY);
//    CGFloat yRange = maxY-minY;
//    if (yRange == 0)
//    {
//        // deal with flat data when yRange is zero and we get maths errors (NaNs). Expand the min/max thresholds to compensate
//        //NSLog(@"Warning: yRange is zero - modifying to prevent maths errors");
//        minY = minY * 0.5f;
//        maxY += maxY - minY;
//        yRange = maxY-minY;
//    }
//
//    CGFloat yScale = viewRangeY / yRange;
//    CGFloat y = (rect.origin.y+rect.size.height) - ((point.y-minY) * yScale);

    CGFloat xScale = viewRangeX / zoomWindow.range;
//    CGFloat x = rect.origin.x + ((point.x-minX) * xScale);

    // number of points at scale 1
    int count = self.count;
    CGFloat sampleSize = (CGFloat)self.count / zoomWindow.

}
*/

/*
- (CGPoint)positionForDataPoint:(ChartDataPoint *)dataPoint inSeries:(ChartSeries *)series atIndex:(NSInteger)index
{
    // get point in data space
    CGPoint point = [self dataSpacePointForDataPoint:dataPoint inSeries:series atIndex:index];
    // convert to view space
    return [series mapPoint:point toViewRect:[self chartContentRect]];
}
*/

#pragma mark - Enumeration

// enumerate all points
//
- (void)enumerateWithBlock:(ChartSeriesEnumerationBlock)block
{
    for (ChartDataPoint *dataPoint in self.dataPoints)
    {
        block(dataPoint);
    }
}

// enumerate all contiguous periods in the series
//
- (void)enumerateContiguousPeriodsWithBlock:(ChartSeriesContiguousPeriodEnumerationBlock)block
{
    BOOL stop = NO;
    for (ChartContiguousPeriodDescriptor *desc in self.contiguousPeriods)
    {
        block(desc, &stop);
        if (stop) break;
    }
}




#pragma mark - contiguity/gap management

//- (CGFloat)meanInterval
//{
//    NSTimeInterval minX = [self.minTimeX timeIntervalSince1970];
//    NSTimeInterval maxX = [self.maxTimeX timeIntervalSince1970];
//    CGFloat xRange = maxX-minX;
//    return xRange / [self.dataPoints count];
//    
//    // &&& THIS IS GARBAGE BCS IT INCLUDES GAPS!!!
//}


- (void)processGaps
{
    NSMutableArray *contiguousPeriods = [[NSMutableArray alloc] initWithCapacity:16];

    double gapInterval;
    NSTimeInterval period = [self dateRange];
    if (period <= kTimeInterval1Day*10)
    {
        // 10-day charts and less have intraday samples, so look for overnight gaps
        gapInterval = 12*kTimeInterval1Hour;
        _isIntraday = YES;
    }
    else
    {
        // otherwise one sample per day, so we look for gaps greater than one day (weekends, holidays)
        gapInterval = kTimeInterval1Day;
        _isIntraday = NO;
    }

    __block NSTimeInterval accInterval = 0;
    __block int accIntervalCount = 0;
    __block double t0 = 0;
    __block double relativeTimeOffset = 0;
    __block NSDate *startDate = nil;
    __block int startIndex = 0, index = 0;
    __block ChartDataPoint *prevDataPoint = nil;
    [self enumerateWithBlock:^(ChartDataPoint *dataPoint) {
        if (index == self.dataPoints.count-1)
        {
            // last data point
//            dataPoint.xValueRelative = dataPoint.xValue;
            double t1 = [self dstSanitisedTime:[dataPoint.xValue valueAsEpochTime]];
            double relativeTime = t1 - relativeTimeOffset;
            dataPoint.xValueRelative = [ChartTimeDataValue valueWithEpochTime:relativeTime];

            ChartContiguousPeriodDescriptor *desc = [[ChartContiguousPeriodDescriptor alloc] init];
            desc.startDate = startDate;
//            desc.duration = [dataPoint.xValue.valueAsDate timeIntervalSinceDate:startDate];
            desc.duration = [prevDataPoint.xValue.valueAsDate timeIntervalSinceDate:startDate];
            desc.nextStartEpoch = dataPoint.xValue.valueAsEpochTime;
            desc.firstDataPointIndex = startIndex;
            desc.lastDataPointIndex = index;      // this data point
            [contiguousPeriods addObject:desc];
        }
        else if (t0 > 0)
        {
            // any data point excluding first and last
            double t1 = [dataPoint.xValue valueAsEpochTime];
            double interval = (CGFloat)(t1-t0);
            //NSLog(@"t0 %0.f t1 %0.f interval %0.f", t0, t1, interval);
            // capture current time before it gets modified
            t0 = t1;// + kTimeIntervalTradingTime;

            if (interval > gapInterval)
            {
                // gap
                // HACK as well
                //relativeTimeOffset += (interval - meanInterval);
                relativeTimeOffset += interval;
//                dataPoint.contiguousStart = YES;

                ChartContiguousPeriodDescriptor *desc = [[ChartContiguousPeriodDescriptor alloc] init];
                desc.startDate = startDate;
//                desc.duration = [dataPoint.xValue.valueAsDate timeIntervalSinceDate:startDate];
                desc.duration = [prevDataPoint.xValue.valueAsDate timeIntervalSinceDate:startDate];
                desc.nextStartEpoch = dataPoint.xValue.valueAsEpochTime;

                // INTRAday samples are fine because they have real times, but with INTERday data the samples run midnight->midnight which means we end up with
                // 72-hour weekends and 4-day weeks. This causes chaos when we try to remove gaps, so sanitise it here.
                if (gapInterval >= kTimeInterval1Day)
                {
                    desc.duration += kTimeInterval1Day;         // inc the duration by a day
                    relativeTimeOffset -= kTimeInterval1Day;    // reduce the gap by a day
                }
                
                desc.firstDataPointIndex = startIndex;
                desc.lastDataPointIndex = index-1;      // data point before gap
                [contiguousPeriods addObject:desc];
//                startDate = dataPoint.xValue.valueAsDate;
                startDate = [NSDate dateWithTimeIntervalSince1970:[self dstSanitisedTime:dataPoint.xValue.valueAsEpochTime]];
                startIndex = index;
            }
            else
            {
                // non-gap interval
                accInterval += interval;
                ++accIntervalCount;
            }
            double relativeTime = t1 - relativeTimeOffset;
            //NSLog(@"t1 %0.f interval %0.f relativeTimeOffset %0.f relativeTime %0.f", t1, interval, relativeTimeOffset, relativeTime);
            dataPoint.xValueRelative = [ChartTimeDataValue valueWithEpochTime:relativeTime];
            
        }
        else
        {
            // first data point
            t0 = [self dstSanitisedTime:[dataPoint.xValue valueAsEpochTime]];
            dataPoint.xValueRelative = dataPoint.xValue;
//            dataPoint.contiguousStart = YES;            // always assume first data point is start of a contiguous run - this may be a problem if API returns first point that does not correspond to start of a run?
            startDate = dataPoint.xValue.valueAsDate;
            startIndex = index;
        }
        prevDataPoint = dataPoint;
        ++index;
    }];
    self.contiguousPeriods = contiguousPeriods;
    // store the actual mean interval in the non-gapping data
    _meanInterval = accInterval / (double)accIntervalCount;
}

- (NSTimeInterval)dstSanitisedTime:(NSTimeInterval)time
{
    NSTimeInterval rem = fmod(time, kTimeInterval1Day);
    if (rem <= kTimeInterval1Hour) time -= rem;
    else if (rem >= 23*kTimeInterval1Hour) time += kTimeInterval1Day-rem;
    return time;
}


#pragma mark - Bezier path generation

- (void)generateCandleBezierPathsInViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre block:(ChartSeriesCandleGeneratorBlock)block
{
    CMKZoomWindow window = [self.xAxis.series zoomWindowForZoomLevel:zoomLevel centre:centre];
    CGFloat sampleWidth = window.range / (CGFloat)window.spanPoints;

    for (int i=window.startIndex; i<window.startIndex+window.spanPoints; i++)
    {
        if (i >= self.dataPoints.count) break;
        
        ChartCandleDataPoint *dataPoint = (ChartCandleDataPoint *)self.dataPoints[i];
        CMKBezierPath *path = [self candlePathForDataPoint:dataPoint sampleWidth:sampleWidth inViewRect:viewRect zoomWindow:window];
        // yield path to caller
        block(dataPoint, path);
    }
}

- (CMKBezierPath *)candlePathForDataPoint:(ChartCandleDataPoint *)dataPoint sampleWidth:(CGFloat)sampleWidth inViewRect:(CGRect)viewRect zoomWindow:(CMKZoomWindow)zoomWindow
{
    CGFloat w = sampleWidth * 0.25f;
    CGFloat x = (CGFloat)[dataPoint.xValueRelative valueAsEpochTime];
    CGPoint openPoint = [self mapPoint:CGPointMake(x-w, dataPoint.openValue.valueAsFloat) toViewRect:viewRect zoomWindow:zoomWindow];
    CGPoint closePoint = [self mapPoint:CGPointMake(x+w, dataPoint.closeValue.valueAsFloat) toViewRect:viewRect zoomWindow:zoomWindow];
    CGPoint highPoint = [self mapPoint:CGPointMake(x, dataPoint.highValue.valueAsFloat) toViewRect:viewRect zoomWindow:zoomWindow];
    CGPoint lowPoint = [self mapPoint:CGPointMake(x, dataPoint.lowValue.valueAsFloat) toViewRect:viewRect zoomWindow:zoomWindow];
    
    CGFloat lowTop = MAX(openPoint.y, closePoint.y);
    CGFloat highBottom = MIN(openPoint.y, closePoint.y);
    
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    // rectangular body
    BZPATH_MOVE_TO(path, openPoint);
    BZPATH_LINE_TO(path, CGPointMake(openPoint.x, closePoint.y));
    BZPATH_LINE_TO(path, closePoint);
    BZPATH_LINE_TO(path, CGPointMake(closePoint.x, openPoint.y));
    BZPATH_LINE_TO(path, openPoint);
    [path closePath];
    // tail to low point
    BZPATH_MOVE_TO(path, lowPoint);
    BZPATH_LINE_TO(path, CGPointMake(lowPoint.x, lowTop));
    [path closePath];
    // tail to high point
    BZPATH_MOVE_TO(path, highPoint);
    BZPATH_LINE_TO(path, CGPointMake(highPoint.x, highBottom));
    [path closePath];

    return path;
}

- (CMKBezierPath *)candleBezierPathInViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre
{
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    
    NSInteger index = 0;
    BOOL started = NO;
    CGPoint point0 = CGPointZero;

    CMKZoomWindow window = [self.xAxis.series zoomWindowForZoomLevel:zoomLevel centre:centre];
    CGFloat sampleWidth = window.range / (CGFloat)window.spanPoints;
    

    for (int i=window.startIndex; i<window.startIndex+window.spanPoints; i++)
    {
        if (i >= self.dataPoints.count) break;
        
        ChartCandleDataPoint *dataPoint = (ChartCandleDataPoint *)self.dataPoints[i];
        CMKBezierPath *subpath = [self candlePathForDataPoint:dataPoint sampleWidth:sampleWidth inViewRect:viewRect zoomWindow:window];
        [path appendPath:subpath];
 
        ++index;
    }
    return path;
}


- (CMKBezierPath *)bezierPathInViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre
{
    //NSLog(@"bezierPathInViewRect zoomLevel %0.3f centre %f", zoomLevel, centre);
    CMKBezierPath *path = nil;
    switch (self.model.smoothingAlgorithm)
    {
        case CMKSeriesSmoothingAlgorithmQuad:
            NSLog(@"CMKSeriesSmoothingAlgorithmQuad not implemented for discontiguous x-axis");
//            path = [self quadSmoothedBezierPathInViewRect:viewRect zoomLevel:zoomLevel centre:centre];
//            break;
        case CMKSeriesSmoothingAlgorithmSpline:
            NSLog(@"CMKSeriesSmoothingAlgorithmSpline not implemented for discontiguous x-axis");
//            path = [self splineSmoothedBezierPathWithGranularity:4 inViewRect:viewRect zoomLevel:zoomLevel centre:centre];
//            break;
        case CMKSeriesSmoothingAlgorithmNone:
        default:
            path = [self rawBezierPathInViewRect:viewRect zoomLevel:zoomLevel centre:centre];
            break;
    }
    //return [self closedPathForPath:path inViewRect:viewRect];
    //[self setLinePatternOnPath:path forStyle:self.model.lineStyle];
    return path;
}

- (CMKBezierPath *)rawBezierPathInViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre
{
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    
//    NSTimeInterval minX = [self.minTimeX timeIntervalSince1970];
//    NSTimeInterval maxX = [self.maxTimeX timeIntervalSince1970];
//    CGFloat xRange = maxX-minX;
//    CGFloat meanDeltaX = xRange / [self.dataPoints count];
    CGFloat meanDeltaX = [self meanInterval];
    
    NSInteger index = 0;
    BOOL started = NO;
    CGPoint point0 = CGPointZero;

//    CMKZoomWindow window = [self zoomWindowForZoomLevel:zoomLevel centre:centre];
    CMKZoomWindow window = [self.xAxis.series zoomWindowForZoomLevel:zoomLevel centre:centre];
    //NSLog(@"zoomLevel %0.1f centre %f start %d span %d", zoomLevel, centre, window.startIndex, window.spanPoints);

    for (int i=window.startIndex; i<window.startIndex+window.spanPoints; i++)
    {
        if (i >= self.dataPoints.count) break;
        
        ChartDataPoint *dataPoint = self.dataPoints[i];
        
        //NSLog(@"dataPoint time %@ tRel %0.f y %0.f", dataPoint.xValue.valueAsDate, dataPoint.xValueRelative.valueAsEpochTime, dataPoint.yValue.valueAsFloat);
        
        // point in data space
//        CGPoint point = [self dataSpacePointForDataPoint:dataPoint];
        CGPoint point = [self relativeDataSpacePointForDataPoint:dataPoint];

        //NSLog(@"relative point (%0.f,%0.f)", point.x, point.y);


        // convert to point in view
        CGPoint p = [self mapPoint:point toViewRect:viewRect zoomWindow:window];

        // TODO: probably need a more statistically rigorous test for discontiguous data
        // If we knew the nominal data interval (e.g. 1 min, daily, etc), we could be more precise. In the absence of that, use the mean as a rough test. (Mode would be better.)
        BOOL discontiguous = ((point.x - point0.x) > meanDeltaX*2.0f);

        // &&& NOTE: Turned off the discontiguous mode - this should probably be a setting
        if (!started /*|| discontiguous*/)
        {
            BZPATH_MOVE_TO(path, p);
            started = YES;
        }
        else
        {
            BZPATH_LINE_TO(path, p);
        }
        ++index;
        point0 = point;
    }
    return path;
}


- (CMKBezierPath *)quadSmoothedBezierPathInViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre
{
//    CMKZoomWindow window = [self zoomWindowForZoomLevel:zoomLevel centre:centre];
    CMKZoomWindow window = [self.xAxis.series zoomWindowForZoomLevel:zoomLevel centre:centre];
    //NSLog(@"zoomLevel %0.1f centre %f start %d span %d", zoomLevel, centre, window.startIndex, window.spanPoints);

    NSMutableArray *values = [NSMutableArray arrayWithCapacity:[self.dataPoints count]];
    for (int i=window.startIndex; i<window.startIndex+window.spanPoints; i++)
    {
        if (i >= self.dataPoints.count) break;

        ChartDataPoint *dataPoint = self.dataPoints[i];
//        // point in data space
        CGPoint point = [self dataSpacePointForDataPoint:dataPoint];
        // convert to point in view
        CGPoint p = [self mapPoint:point toViewRect:viewRect zoomWindow:window];

        //NSLog(@"adding point (%0.3f,%0.3f)", p.x, p.y);

        [values addObject:[NSValue valueWithCGPoint:p]];
    }
    
    return [CMKBezierPath quadCurvedPathWithPoints:values];
}


- (CMKBezierPath *)splineSmoothedBezierPathWithGranularity:(NSInteger)granularity inViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre
{
    return [[self rawBezierPathInViewRect:viewRect zoomLevel:zoomLevel centre:centre] smoothedPathWithGranularity:granularity];
}

// Given a path representing a line chart, return a copy that is closed around the bottom of view rect.
// Used to create fill paths for line charts.
//
- (CMKBezierPath *)closedPathForPath:(CMKBezierPath *)path inViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre
{
    NSArray *points = [self bezierPointsForPath:path];
    CGPoint p0 = [[points firstObject] CGPointValue];
    CGPoint p1 = [[points lastObject] CGPointValue];

    //NSLog(@"p0 %@ p1 %@", NSStringFromCGPoint(p0), NSStringFromCGPoint(p1));


    CMKBezierPath *closedPath = [CMKBezierPath bezierPathWithCGPath:path.CGPath];
    BZPATH_LINE_TO(closedPath, CGPointMake(p1.x, viewRect.origin.y+viewRect.size.height));
    BZPATH_LINE_TO(closedPath, CGPointMake(p0.x, viewRect.origin.y+viewRect.size.height));
    [closedPath closePath];
    return closedPath;
}




- (CMKBezierPath *)dataPointMarksBezierPathForModel:(CMKTickMarksModel *)model inViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre
{
//    CMKZoomWindow window = [self zoomWindowForZoomLevel:zoomLevel centre:centre];
    CMKZoomWindow window = [self.xAxis.series zoomWindowForZoomLevel:zoomLevel centre:centre];
    
    CGRect dataBounds = viewRect;
    CGSize size = model.size;

    CMKBezierPath *path = [CMKBezierPath bezierPath];
    [self enumerateWithBlock:^(ChartDataPoint *dataPoint) {
        
        CGFloat hs = size.height * 0.5f;
        //NSLog(@"model tag %@", model.tag);

        // point in data space
        CGPoint point = [self dataSpacePointForDataPoint:dataPoint];
        // convert to point in view
        CGPoint p = [self mapPoint:point toViewRect:viewRect zoomWindow:window];
        
        {
            CGPoint p0 = p;//CGPointMake(gridlineViewPointStart.x, (farOrigin ? axisBounds.origin.y+axisBounds.size.height : axisBounds.origin.y));
//            if (pos & CMKTickmarksPositionNear)
            {
                
                CMKBezierPath *divPath = [CMKBezierPath bezierPath];
                [model addTickMarkToPath:path atPoint:p0];
                BZPATH_APPEND(path, divPath);
            }
        }
        
    }];
    return path;
}

#pragma mark - Bezier path access support methods

- (NSArray *)bezierPointsForPath:(CMKBezierPath *)path
{
    NSMutableArray *points = [NSMutableArray array];
    CGPathApply(path.CGPath, (__bridge void *)points, getBezierElements);
    return points;
}

void getBezierElements(void *info, const CGPathElement *element)
{
    NSMutableArray *points = (__bridge NSMutableArray *)info;
    switch (element->type)
    {
        case kCGPathElementMoveToPoint:
            [points addObject:[NSValue valueWithCGPoint:element->points[0]]];
            break;
        case kCGPathElementAddLineToPoint:
            [points addObject:[NSValue valueWithCGPoint:element->points[0]]];
            break;
        case kCGPathElementAddQuadCurveToPoint:
            [points addObject:[NSValue valueWithCGPoint:element->points[1]]];
            break;
        case kCGPathElementAddCurveToPoint:
            [points addObject:[NSValue valueWithCGPoint:element->points[2]]];
            break;
        default:
            break;
    }
}


#pragma mark - shape generation

// Create a mask for the chart fill area
// path should be closed
//
- (CAShapeLayer *)maskForPath:(CMKBezierPath *)path inViewRect:(CGRect)viewRect
{
    path.lineWidth = self.model.lineStyle.lineWidth;

    CAShapeLayer *mask = [[CAShapeLayer alloc] init];
    mask.frame = viewRect;
    mask.path = path.CGPath;
    mask.fillColor = [UIColor blackColor].CGColor;
    return mask;
}


// Create a gradient shape for the chart fill area, with the specified colours
// path should be closed
//
- (CAGradientLayer *)gradientShapeForPath:(CMKBezierPath *)path fromColor:(CMKColor *)fromColor toColor:(CMKColor *)toColor inViewRect:(CGRect)viewRect
{
    CAShapeLayer *mask = [self maskForPath:path inViewRect:viewRect];

    CAGradientLayer *grad = [[CAGradientLayer alloc] init];
    grad.frame = viewRect;
    grad.colors = @[(id)fromColor.CGColor, (id)toColor.CGColor];
    grad.mask = mask;
    
    return grad;
}

// Create a gradient shape for the chart fill area, with the specified colour array
// path should be closed
//
- (CAGradientLayer *)gradientShapeForPath:(CMKBezierPath *)path colors:(NSArray *)colors inViewRect:(CGRect)viewRect
{
    CAShapeLayer *mask = [self maskForPath:path inViewRect:viewRect];

    CAGradientLayer *grad = [[CAGradientLayer alloc] init];
    grad.frame = viewRect;
    grad.colors = colors;
    grad.mask = mask;
    
    return grad;
}

// Create a gradient shape for the chart fill area, using the gradient colours from the model
// path should be closed
//
- (CAGradientLayer *)gradientShapeForPath:(CMKBezierPath *)path inViewRect:(CGRect)viewRect
{
    NSMutableArray *colors = [NSMutableArray arrayWithCapacity:[self.model.fillColors count]];
    if (self.model.fillColors && [self.model.fillColors count] > 0)
    {
        for (CMKColorModel *colorModel in self.model.fillColors)
        {
            [colors addObject:(id)[CMKColor colorWithARGB:colorModel.colorValue].CGColor];
        }
    }
    else
    {
        NSLog(@"Warning: series model does not have any fillColors: gradient colors will be undefined");
    }
    return [self gradientShapeForPath:path colors:colors inViewRect:viewRect];
}


// Create a shape for the chart line
//
- (CAShapeLayer *)lineShapeForPath:(CMKBezierPath *)path inViewRect:(CGRect)viewRect
{
    CMKColor *strokeColor = [CMKColor colorWithARGB:(int)self.model.lineStyle.lineColor.colorValue];

    // shape can be used for line without rest of path closure
    CAShapeLayer *shape = [[CAShapeLayer alloc] init];
    shape.frame = viewRect;
    shape.path = path.CGPath;
    shape.strokeColor = strokeColor.CGColor;
    shape.lineWidth = self.model.lineStyle.lineWidth;
    shape.fillColor = nil;
    shape.lineCap = [self.model.lineStyle lineEndCapStyleAsCAString];
    shape.lineJoin = [self.model.lineStyle lineJoinStyleAsCAString];
    [[self class] setDashPatternOnShape:shape forStyle:self.model.lineStyle];

    return shape;
}

- (CAShapeLayer *)dataPointsShapeForModel:(CMKTickMarksModel *)model withPath:(UIBezierPath *)path tag:(NSString *)tag inViewRect:(CGRect)viewRect
{
    CMKColor *tickMarksColor = [CMKColor colorWithARGB:(int)model.lineStyle.lineColor.colorValue];
    CAShapeLayer *shape = [[CAShapeLayer alloc] init];
//    NSString *tag = [NSString stringWithFormat:@"datapointmarks-%@", (model.tag ? model.tag : @"")];
    [shape setName:tag];
    shape.frame = viewRect;
    shape.path = path.CGPath;
    shape.lineWidth = model.lineStyle.lineWidth;
    shape.strokeColor = tickMarksColor.CGColor;
    if (model.customPath.fillColor)
    {
        shape.fillColor = [UIColor colorWithARGB:model.customPath.fillColor.colorValue].CGColor;
    }
    else
    {
        shape.fillColor = (model.style == CMKTickMarkStyleDot ? shape.strokeColor : nil);
    }
    shape.lineCap = [model.lineStyle lineEndCapStyleAsCAString];
    shape.lineJoin = [model.lineStyle lineJoinStyleAsCAString];
    [ChartSeries setDashPatternOnShape:shape forStyle:model.lineStyle];
    
    return shape;
}

#pragma mark - line pattern methods

+ (void)setLinePatternOnPath:(CMKBezierPath *)path forStyle:(CMKLineStyleModel *)style
{
    if (style.dashPattern)
    {
        NSArray *pattern = [style dashPatternAsArray];
        if (pattern && [pattern count] > 0)
        {
            [path setDashPatternFromArray:pattern];
        }
    }
    else
    {
        switch (style.simpleLineStyle)
        {
            case CMKLineStyleDashed:
            {
                CGFloat dashes[] = {5,5};
                [path setLineDash:dashes count:2 phase:0];
                break;
            }
            case CMKLineStyleDotted:
            {
                CGFloat dashes[] = {2,2};
                [path setLineDash:dashes count:2 phase:0];
                break;
            }

            case CMKLineStyleSolid:
            case CMKLineStyleNone:
            default:
                break;
        }
    }
}


+ (void)setDashPatternOnShape:(CAShapeLayer *)shape forStyle:(CMKLineStyleModel *)style
{
    if (style.dashPattern)
    {
        shape.lineDashPattern = [style dashPatternAsArray];
    }
    else
    {
        switch (style.simpleLineStyle)
        {
            case CMKLineStyleDashed:
            {
                shape.lineDashPattern = @[@5,@5];
                break;
            }
            case CMKLineStyleDotted:
            {
                shape.lineDashPattern = @[@2,@2];
                break;
            }

            case CMKLineStyleSolid:
            case CMKLineStyleNone:
            default:
                break;
        }
    }
}

#pragma mark - helpers

+ (ChartSeries *)emaSeriesFromSeries:(ChartSeries *)series withPeriod:(int)period
{
    __block float ema = [[series dataPointAtIndex:0].yValue valueAsFloat];
    __block ChartSeries *emaSeries = [[ChartSeries alloc] init];
    [series enumerateWithBlock:^(ChartDataPoint *dataPoint) {
        ChartTimeSeriesDataPoint *dp = (ChartTimeSeriesDataPoint *)dataPoint;
        ema = calculateEMA([dp.yValue valueAsFloat], period, ema);
        
        ChartTimeSeriesDataPoint *emaDataPoint = [ChartTimeSeriesDataPoint timeSeriesDataPointWithDate:[dp.xValue valueAsDate] andValue:@(ema)];
        [emaSeries addDataPoint:emaDataPoint];
    }];
    return emaSeries;
}







@end
