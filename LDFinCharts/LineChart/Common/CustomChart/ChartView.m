//
//  ChartView.m
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 26/02/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "ChartView.h"
#import "ChartSeries.h"
#import "ChartXAxis.h"
#import "ChartYAxis.h"
#import "NSDate+ChartFormatting.h"
#import "CMKColor+CMKExtensions.h"
#import "CMKBezierPath+Smoothing.h"
#import "CALayer+Extensions.h"
#import "CMKBezierPath+CMKExtensions.h"

NSString * const LDChartViewErrorDomain = @"com.leedowthwaite.chartview";



//#define ENABLE_ZOOM
//#define ENABLE_PAN
//#define ENABLE_OVERLAY_CROSSHAIRS
//#define ENABLE_OVERLAY_TAP
//#define ENABLE_OVERLAY_LABEL_OUTLINES

//#define DEBUG_SHOW_BOUNDS
//#define OVERRIDE_DRAWRECT

@interface ChartView()
{
    CMKZoomWindow _zoomWindow;
    CGFloat _lastZoomLevel;
    CGFloat _lastCentreOffset;
}
@property (nonatomic, strong) NSArray *series;
@property (nonatomic, strong) NSArray *seriesPaths;
@property (nonatomic, strong) NSArray *seriesShapes;
@property (nonatomic, strong) CAShapeLayer *xAxisShape;
@property (nonatomic, strong) CAShapeLayer *yAxisShape;
@property (nonatomic, strong) CAShapeLayer *intersectionsShape;
@property (nonatomic, strong) CAShapeLayer *xAxisOverlayShape;
@property (nonatomic, assign) BOOL overlayInteractionTouchActive;
@property (nonatomic, assign) CGPoint overlayInteractionTouchPosition;
@end

@implementation ChartView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setup];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
#ifdef ENABLE_ZOOM
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self addGestureRecognizer:pinchGestureRecognizer];
#endif
#ifdef ENABLE_PAN
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:panGestureRecognizer];
#endif
#ifdef ENABLE_OVERLAY_CROSSHAIRS
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self addGestureRecognizer:longPressGestureRecognizer];
#endif
#ifdef ENABLE_OVERLAY_TAP
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self addGestureRecognizer:tapGestureRecognizer];
#endif
    self.currentZoomLevel = _lastZoomLevel = 1.0f;
    _currentCentreOffset = 0;
    _lastCentreOffset = 0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(annotationControllerDismissed:) name:@"AnnotationControllerDismissed" object:nil];
    
}

// set the model to (re)create all the dependent objects
- (void)setModel:(ChartModel *)model
{
    _model = model;
    self.xAxis = (ChartXAxis *)[ChartXAxis axisWithModel:model.xAxisModel];
    self.xAxis.delegate = self;
    self.yAxis = (ChartYAxis *)[ChartYAxis axisWithModel:model.yAxisModel];
    self.yAxis.delegate = self;
}

- (void)setGradientMaskForRect:(CGRect)rect
{
    self.layer.mask = [self gradientShapeFromColor:UIColor.whiteColor toColor:[UIColor colorWithARGB:0x40ffffff] inViewRect:rect];
}

- (void)removeGradientMask
{
    self.layer.mask = nil;
}

- (void)setOverlayHidden:(BOOL)hidden
{
    self.xAxisOverlayShape.hidden = hidden;
}

- (BOOL)isFlipped
{
    return YES;
}

- (BOOL)isSeriesValid:(ChartSeries *)series
{
    return series && ([series count] > 1);
}

#pragma mark - update

- (void)update
{
    ChartSeries *series = self.xAxis.series;
    if (![self isSeriesValid:series])
    {
        NSLog(@"ChartView update: series is nil, aborting");
        return;
    }

    CGFloat xOffset = self.currentCentreOffset;
    
    // If shape layers flicker, it's due to performance hit (and possibly frame buffering issues?) by implementing drawRect. Totally smooth without it.

    // update paths of all shapes
    for (int i=0; i<[self.series count]; i++)
    {
        ChartSeries *series = self.series[i];
        if (![self isSeriesValid:series])
        {
            NSLog(@"ChartView update: series is nil, aborting");
            return;
        }
        CAShapeLayer *lineShape = self.seriesShapes[i];
        double centre = [series range] * 0.5 - xOffset;

        if (series.model.category == CMKSeriesCategoryLine)
        {
            CMKBezierPath *path = [series bezierPathInViewRect:[self dataViewBounds] zoomLevel:self.currentZoomLevel centre:centre];
            CAShapeLayer *fillShape = (CAShapeLayer *)([lineShape sublayerNamed:@"fill"]);
            if (fillShape)
            {
                CMKBezierPath *closedPath = [series closedPathForPath:path inViewRect:[self dataViewBounds] zoomLevel:self.currentZoomLevel centre:centre];
                fillShape.path = closedPath.CGPath;
            }

            CAGradientLayer *gradientShape = (CAGradientLayer *)([lineShape sublayerNamed:@"gradient"]);
            if (gradientShape)
            {
                CMKBezierPath *closedPath = [series closedPathForPath:path inViewRect:[self dataViewBounds] zoomLevel:self.currentZoomLevel centre:centre];
                // use new path to build mask to apply to gradient
                gradientShape.mask = [series maskForPath:closedPath inViewRect:[self activeViewBounds]];
                // remember to update the gradient's frame during animation
                gradientShape.frame = [self activeViewBounds];
            }
            lineShape.path = path.CGPath;
        }
        else if (series.model.category == CMKSeriesCategoryCandle)
        {
            CAShapeLayer *candlesContainerShape = (CAShapeLayer *)[lineShape sublayerNamed:@"candles"];
            [candlesContainerShape removeFromSuperlayer];
            candlesContainerShape = [[CAShapeLayer alloc] init];
            candlesContainerShape.name = @"candles";
            CMKColorModel *colorModel1 = series.model.fillColors[0];
            CMKColorModel *colorModel2 = series.model.fillColors[1];
            CGColorRef fillColor1 = colorModel1.color.CGColor;
            CGColorRef fillColor2 = colorModel2.color.CGColor;
            [series generateCandleBezierPathsInViewRect:[self dataViewBounds] zoomLevel:self.currentZoomLevel centre:centre block:^(ChartCandleDataPoint * _Nonnull dataPoint, UIBezierPath * _Nonnull path) {
                CAShapeLayer *candleShape = [[CAShapeLayer alloc] init];
                candleShape.path = path.CGPath;
                candleShape.lineWidth = 0.5f;
                candleShape.strokeColor = UIColor.whiteColor.CGColor;
                candleShape.fillColor = (dataPoint.closeValue.valueAsFloat > dataPoint.openValue.valueAsFloat ? fillColor1 : fillColor2);
                [candlesContainerShape addSublayer:candleShape];
            }];
            [lineShape addSublayer:candlesContainerShape];
        }

        // clipping mask - need to update this in case we're animating
        CAShapeLayer *clip = [[CAShapeLayer alloc] init];
        clip.path = [CMKBezierPath bezierPathWithRect:[self dataViewBounds]].CGPath;
        lineShape.mask = clip;
        
        if (series.model.dataPointMarks)
        {
            // tickmarks
            // look at what tickmark models are present
            int idx = 0;
            for (CMKTickMarksModel *model in series.model.dataPointMarks)
            {
                NSString *tag = [NSString stringWithFormat:@"datapointmarks-%@", (model.tag ? model.tag : [NSString stringWithFormat:@"%d", idx])];
                CAShapeLayer *tickmarksShape = (CAShapeLayer *)[lineShape sublayerNamed:tag];
                tickmarksShape.path = [series dataPointMarksBezierPathForModel:model inViewRect:[self dataViewBounds] zoomLevel:self.currentZoomLevel centre:centre].CGPath;
                ++idx;
            }
        }
    }

    // get the zoom window and apply to axes, using pan offset so axes scroll accordingly
    _zoomWindow = [series zoomWindowForZoomLevel:self.currentZoomLevel centre:[series range] * 0.5 - xOffset];
    self.xAxis.zoomWindow = &_zoomWindow;
    //self.yAxis.zoomWindow = &_zoomWindow;
    // update axis shape paths
    [self.xAxis updatePathsForAxisShape:self.xAxisShape];
    [self.yAxis updatePathsForAxisShape:self.yAxisShape];

    // update the intersections path
    if (self.intersectionsShape)
    {
        self.intersectionsShape.path = [self pathForAxisIntersections].CGPath;
    }
    
    [self updateOverlay];
}


- (void)updateOverlay
{
    [self setOverlayHidden:!self.overlayInteractionTouchActive];
    if (self.xAxisOverlayShape && self.overlayInteractionTouchActive)
    {
        CMKBezierPath *path = [self pathForXAxisOverlay];
        self.xAxisOverlayShape.path = path.CGPath;
        
        CAShapeLayer *intersectionShape = (CAShapeLayer *)[self.xAxisOverlayShape sublayerNamed:@"x-axis-overlay-datapoint-intersection"];
        intersectionShape.path = [self pathForXAxisOverlayIntersection].CGPath;

#ifdef ENABLE_OVERLAY_LABEL_OUTLINES
        CAShapeLayer *xLabelOutlineShape = (CAShapeLayer *)[self.xAxisOverlayShape sublayerNamed:@"x-axis-overlay-label-outline"];
        xLabelOutlineShape.path = [self pathForXAxisOverlayLabelOutline].CGPath;
#endif
        CAShapeLayer *xLabelShape = (CAShapeLayer *)[self.xAxisOverlayShape sublayerNamed:@"x-axis-overlay-label"];
        xLabelShape.path = [self pathForXAxisOverlayLabel].CGPath;

#ifdef ENABLE_OVERLAY_LABEL_OUTLINES
        CAShapeLayer *yLabelOutlineShape = (CAShapeLayer *)[self.xAxisOverlayShape sublayerNamed:@"y-axis-overlay-label-outline"];
        yLabelOutlineShape.path = [self pathForYAxisOverlayLabelOutline].CGPath;
#endif
        CAShapeLayer *yLabelShape = (CAShapeLayer *)[self.xAxisOverlayShape sublayerNamed:@"y-axis-overlay-label"];
        yLabelShape.path = [self pathForYAxisOverlayLabel].CGPath;


    }
}

#pragma mark - layer management

// relayout layers by removing all sublayers and adding them in again.
//
- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    @synchronized(self)
    {
        if (layer == self.layer)
        {
            NSArray *sublayers = [layer.sublayers copy];
            //NSLog(@"layout sublayers, current count %ld", [sublayers count]);
            assert ([sublayers count] < 20);
            for (CALayer *subLayer in sublayers)
            {
                [subLayer removeFromSuperlayer];
            }
        
            for (CAShapeLayer *shapeLayer in self.seriesShapes)
            {
                [layer addSublayer:shapeLayer];
            }
            
            [layer addSublayer:self.intersectionsShape];
            [layer addSublayer:self.xAxisShape];
            [layer addSublayer:self.yAxisShape];
            [layer addSublayer:self.xAxisOverlayShape];
       }
    }
}


#pragma mark - data management

// heavy-duty method that reloads all data by calling the delegate and completely wiping and laying out the view
- (void)reloadData:(NSError * __autoreleasing *)errorResult
{
    // Ensure NS_BLOCK_ASSERTIONS is defined in release version to turn off the asserts and silently fail

    if (!self.dataSource)
    {
        NSLog(@"Error: no data source, aborting");
        *errorResult = [NSError errorWithDomain:LDChartViewErrorDomain code:LDChartViewErrorNoSourceData userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Missing dataSource", nil)}];
        return;
    }
    if (!self.model)
    {
        NSLog(@"Error: no model, aborting");
        *errorResult = [NSError errorWithDomain:LDChartViewErrorDomain code:LDChartViewErrorNoModel userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Missing data model", nil)}];
        return;
    }
    
    // Load all the series from the delegate
    //
    
    // TODO: maybe make the callbacks async
    NSInteger seriesCount = [self.dataSource numberOfSeriesForChartView:self];
    if (seriesCount <= 0)
    {
        NSLog(@"Error: seriesCount <= 0, aborting");
        *errorResult = [NSError errorWithDomain:LDChartViewErrorDomain code:LDChartViewErrorNoSeries userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Missing data series", nil)}];
        return;
    }
    
    NSMutableArray *seriesArray = [NSMutableArray arrayWithCapacity:seriesCount];
    NSMutableArray *seriesPaths = [NSMutableArray arrayWithCapacity:seriesCount];
    
    //ChartSeries *cumulativeSeries = [[ChartSeries alloc] init];
    
    for (NSInteger seriesIndex=0; seriesIndex<seriesCount; seriesIndex++)
    {
        NSInteger dataPointsCount = [self.dataSource chartView:self numberOfDataPointsForSeriesIndex:seriesIndex];
        if (dataPointsCount > 0)
        {
            // allow datasource to create and manage series
            ChartSeries *series = [self.dataSource chartView:self seriesForIndex:seriesIndex];
            assert(series);
            
            // assign a series model - this is done by array order, so series model index must match series index
            if (seriesIndex < [_model.seriesModels count])
            {
                series.model = _model.seriesModels[seriesIndex];
            }
            else
            {
                NSLog(@"Warning: series index %ld exceeds number of series models (%ld): using last series style", seriesIndex, [_model.seriesModels count]);
                series.model = _model.seriesModels.lastObject;
            }
            // store the series
            [seriesArray addObject:series];

            // add the series to the axes
            [self.xAxis addSeries:series];
            [self.yAxis addSeries:series];
            
//            [cumulativeSeries addSeries:series];
        }
    }

    // build contiguity info for combined axis series
    [self.xAxis.series processGaps];
    
    for (NSInteger seriesIndex=0; seriesIndex<seriesCount; seriesIndex++)
    {
        NSInteger dataPointsCount = [self.dataSource chartView:self numberOfDataPointsForSeriesIndex:seriesIndex];
        // need at least two points to create range
        if (dataPointsCount > 1)
        {
            // allow datasource to create and manage series
            ChartSeries *series = [self.dataSource chartView:self seriesForIndex:seriesIndex];
            if (!series)
            {
                *errorResult = [NSError errorWithDomain:LDChartViewErrorDomain code:LDChartViewErrorNoSeries userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Missing data series", nil)}];
                //NSAssert(series, @"missing series");
                return;
            }

            if (series.derivedFrom)
            {
                if (series.derivedFrom.count == series.count)
                {
                    // for derived series, copy all the relative data point values from the source series. This means we only have to perform gap processing once.
                    for (int index=0; index<series.count; index++)
                    {
                        ChartTimeSeriesDataPoint *ddp = series.dataPoints[index];
                        ChartTimeSeriesDataPoint *sdp = series.derivedFrom.dataPoints[index];
                        ddp.xValueRelative = sdp.xValueRelative;
                    }
                }
                else
                {
                    NSAssert(false, @"series count mismatch - ignoring derived series");
                    return;
                }
            }

            // create a Bezier path from the series
            double range = [series range];
            if (range > 0)
            {
                CMKBezierPath *path = nil;
                if (series.model.category == CMKSeriesCategoryCandle)
                {
                    //path = [series candleBezierPathInViewRect:[self dataViewBounds] zoomLevel:1.0 centre:range*0.5];
                }
                else if (series.model.category == CMKSeriesCategoryLine)
                {
                    path = [series bezierPathInViewRect:[self dataViewBounds] zoomLevel:1.0 centre:range*0.5];
                }
            
                if (path)
                {
                    [seriesPaths addObject:path];
                }
            }
            else
            {
                //NSAssert(range > 0, @"range is 0");
                *errorResult = [NSError errorWithDomain:LDChartViewErrorDomain code:LDChartViewErrorRangeZero userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Range is zero", nil)}];
                return;
            }
        }
        else
        {
            NSLog(@"not enough data points - silently failing because this can happen with a brand new stock");
            *errorResult = [NSError errorWithDomain:LDChartViewErrorDomain code:LDChartViewErrorMissingDataPoints userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Not enough data points", nil)}];
            
            // TODO: need to return an error or exception so we can hide chart here
            
            //NSAssert(dataPointsCount > 1, @"not enough data points");
            return;
        }
    }

    // Store the series and the series paths we just created
    //
    if ([seriesArray count] > 0)
    {
        self.series = seriesArray;
        self.seriesPaths = seriesPaths;
//        self.xAxis.series = cumulativeSeries;// self.series[0];
//        self.yAxis.series = cumulativeSeries;//self.series[0];
    }

    if (!self.series)
    {
        NSLog(@"Error: nil series - aborting");
        *errorResult = [NSError errorWithDomain:LDChartViewErrorDomain code:LDChartViewErrorNilSeries userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Nil series", nil)}];
        return;
    }

    // Create CAShapeLayers to actually display the chart layers
    //
    NSMutableArray *lineShapes = [NSMutableArray array];
    // create a master line shape for each series, with sub-shapes for e.g. fills
    for (int seriesIndex=0; seriesIndex<[self.series count]; seriesIndex++)
    {
        CAShapeLayer *lineShape = nil;
        ChartSeries *series = self.series[seriesIndex];
//        if (seriesIndex >= [self.seriesPaths count]) continue;
//        CMKBezierPath *path = self.seriesPaths[seriesIndex];
//        if (!path) continue;
//
//        // create shape for actual line
//        CAShapeLayer *lineShape = [series lineShapeForPath:path inViewRect:self.bounds];

        if (series.model.category == CMKSeriesCategoryLine)
        {
            // &&& HACK assume series 0 is candle, so first line series is index 1
            int lineSeriesIndex = (seriesIndex > 0 ? seriesIndex-1 : 0);
            if (lineSeriesIndex >= self.seriesPaths.count)
            {
                NSLog(@"array out of bounds");
                *errorResult = [NSError errorWithDomain:LDChartViewErrorDomain code:LDChartViewErrorArrayOutOfBounds userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Array out of bounds", nil)}];
                return;
            }
            CMKBezierPath *path = self.seriesPaths[lineSeriesIndex];

            // create shape for actual line
            lineShape = [series lineShapeForPath:path inViewRect:[self activeViewBounds]];

            // if the model has any fill colors, use the number of them to determine if it's a flat fill or gradient fill
            if (series.model.fillColors)
            {
                // create a closed path around the data area
                // Using the axis bounds creates the correct closed path, since it accounts for possible padding at the bottom (between the data area and the axis),
                // but the edges are correctly clipped to the actual data series.
                CMKBezierPath *closedPath = [series closedPathForPath:path inViewRect:[self axisViewBounds] zoomLevel:1.0 centre:[series range]*0.5];

                if ([series.model.fillColors count] >= 2)
                {
                    // more than one colour: gradient fill
                    // create gradient and line shapes in the view space (all path points are already mapped to view space)
                    CAGradientLayer *gradientShape = [series gradientShapeForPath:closedPath inViewRect:[self activeViewBounds]];
                    [gradientShape setName:@"gradient"];
                    [lineShape addSublayer:gradientShape];
                }
                else if ([series.model.fillColors count] == 1)
                {
                    // single colour: flat fill
                    CMKColorModel *colorModel = series.model.fillColors[0];
                    // create gradient and line shapes in the view space (all path points are already mapped to view space)
                    CAShapeLayer *fillShape = [series maskForPath:closedPath inViewRect:[self activeViewBounds]];
                    fillShape.fillColor = [CMKColor colorWithARGB:colorModel.colorValue].CGColor;
                    [fillShape setName:@"fill"];
                    [lineShape addSublayer:fillShape];
                }
            }
        }
        else if (series.model.category == CMKSeriesCategoryCandle)
        {
            lineShape = [[CAShapeLayer alloc] init];
            CAShapeLayer *candlesContainerShape = [[CAShapeLayer alloc] init];
            candlesContainerShape.name = @"candles";
            [lineShape addSublayer:candlesContainerShape];
        }
        
        if (series.model.dataPointMarks)
        {
            // look at what tickmark models are present
            int idx = 0;
            for (CMKTickMarksModel *model in series.model.dataPointMarks)
            {
                CMKBezierPath *path = [series dataPointMarksBezierPathForModel:model inViewRect:[self dataViewBounds] zoomLevel:1.0 centre:[series range]*0.5];
                NSString *tag = [NSString stringWithFormat:@"datapointmarks-%@", (model.tag ? model.tag : [NSString stringWithFormat:@"%d", idx])];
                CAShapeLayer *shape = [series dataPointsShapeForModel:model withPath:path tag:tag inViewRect:[self activeViewBounds]];
                [lineShape addSublayer:shape];
                ++idx;
            }
        }

        // clipping mask
        CAShapeLayer *clip = [[CAShapeLayer alloc] init];
        clip.path = [CMKBezierPath bezierPathWithRect:[self dataViewBounds]].CGPath;
        lineShape.mask = clip;

        [lineShapes addObject:lineShape];
    }
    // store the shapes array
    self.seriesShapes = lineShapes;

    [self createAxes];
    [self createAxisIntersections];

#ifdef ENABLE_OVERLAY_CROSSHAIRS
    [self createXAxisOverlay];
#endif


    [self update];

#if TARGET_OS_IPHONE
//    [self setNeedsDisplay];
//    [self layoutSublayersOfLayer:self.layer];
#else
    [self setNeedsDisplay:YES];
#endif
}


#pragma mark - overlay management

- (void)createXAxisOverlay
{
    CAShapeLayer *shape = [self shapeLayerWithName:@"x-axis-overlay"];
    shape.lineWidth = 1.0;
    shape.strokeColor = UIColor.whiteColor.CGColor;
    CMKBezierPath *path = [self pathForXAxisOverlay];
    shape.path = path.CGPath;
    self.xAxisOverlayShape = shape;
    [self.layer addSublayer:shape];

    CAShapeLayer *dataPointIntersectionShape = [self shapeLayerWithName:@"x-axis-overlay-datapoint-intersection"];
    dataPointIntersectionShape.lineWidth = 2.0;  //tickmarksModel.lineStyle.lineWidth;
    dataPointIntersectionShape.strokeColor = UIColor.redColor.CGColor;  //[UIColor colorWithARGB:tickmarksModel.lineStyle.lineColor.colorValue].CGColor;
    path = [self pathForXAxisOverlayIntersection];
    dataPointIntersectionShape.path = path.CGPath;
    [self.xAxisOverlayShape addSublayer:dataPointIntersectionShape];

#ifdef ENABLE_OVERLAY_LABEL_OUTLINES
    CAShapeLayer *xAxisLabelOutlineShape = [self shapeLayerWithName:@"x-axis-overlay-label-outline"];
    xAxisLabelOutlineShape.lineWidth = 1.0;
    xAxisLabelOutlineShape.strokeColor = UIColor.whiteColor.CGColor;
    xAxisLabelOutlineShape.fillColor = UIColor.blueColor.CGColor;
    [self.xAxisOverlayShape addSublayer:xAxisLabelOutlineShape];
#endif
    CAShapeLayer *xAxisLabelShape = [self shapeLayerWithName:@"x-axis-overlay-label"];
    xAxisLabelShape.lineWidth = 1.0;
    xAxisLabelShape.strokeColor = UIColor.whiteColor.CGColor;
    [self.xAxisOverlayShape addSublayer:xAxisLabelShape];
    
#ifdef ENABLE_OVERLAY_LABEL_OUTLINES
    CAShapeLayer *yAxisLabelOutlineShape = [self shapeLayerWithName:@"y-axis-overlay-label-outline"];
    yAxisLabelOutlineShape.lineWidth = 1.0;
    yAxisLabelOutlineShape.strokeColor = UIColor.whiteColor.CGColor;
    yAxisLabelOutlineShape.fillColor = UIColor.blueColor.CGColor;
    [self.xAxisOverlayShape addSublayer:yAxisLabelOutlineShape];
#endif
    CAShapeLayer *yAxisLabelShape = [self shapeLayerWithName:@"y-axis-overlay-label"];
    yAxisLabelShape.lineWidth = 1.0;
    yAxisLabelShape.strokeColor = UIColor.whiteColor.CGColor;
    yAxisLabelShape.path = [self pathForYAxisOverlayLabel].CGPath;
    [self.xAxisOverlayShape addSublayer:yAxisLabelShape];
}

- (CAShapeLayer *)shapeLayerWithName:(NSString *)name
{
    CAShapeLayer *shape = [[CAShapeLayer alloc] init];
    [shape setName:name];
    shape.frame = [self activeViewBounds]; //self.bounds;
    return shape;
}


- (CMKBezierPath *)pathForXAxisOverlay
{
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    if (self.overlayInteractionTouchActive)
    {
        CMKBezierPath *xPath = [self.xAxis pathForXAxisOverlayAtViewPosition:self.overlayInteractionTouchPosition];

        ChartDataPoint *dataPoint = [self.xAxis dataPointForViewPosition:self.overlayInteractionTouchPosition inViewRect:[self axisViewBounds]];
        CMKBezierPath *yPath = [self.yAxis pathForYAxisOverlayForDataPoint:dataPoint inViewRect:[self axisViewBounds]];
        [path appendPath:xPath];
        [path appendPath:yPath];
    }
    return path;
}

- (CMKBezierPath *)pathForXAxisOverlayIntersection
{
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    if (self.overlayInteractionTouchActive)
    {
        path = [self.xAxis pathForXAxisOverlayIntersectionAtViewPosition:self.overlayInteractionTouchPosition];
    }
    return path;
}

- (CMKBezierPath *)pathForYAxisOverlayLabel
{
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    if (self.overlayInteractionTouchActive)
    {
        ChartDataPoint *dataPoint = [self.xAxis dataPointForViewPosition:self.overlayInteractionTouchPosition inViewRect:[self axisViewBounds]];
        path = [self.yAxis pathForYAxisOverlayLabelForDataPoint:dataPoint inViewRect:[self axisViewBounds]];
    }
    return path;
}

- (CMKBezierPath *)pathForYAxisOverlayLabelOutline
{
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    if (self.overlayInteractionTouchActive)
    {
        ChartDataPoint *dataPoint = [self.xAxis dataPointForViewPosition:self.overlayInteractionTouchPosition inViewRect:[self axisViewBounds]];
        path = [self.yAxis pathForYAxisOverlayLabelOutlineForDataPoint:dataPoint inViewRect:[self axisViewBounds]];
    }
    return path;
}

- (CMKBezierPath *)pathForXAxisOverlayLabel
{
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    if (self.overlayInteractionTouchActive)
    {
        ChartDataPoint *dataPoint = [self.xAxis dataPointForViewPosition:self.overlayInteractionTouchPosition inViewRect:[self axisViewBounds]];
        path = [self.xAxis pathForXAxisOverlayLabelForDataPoint:dataPoint inViewRect:[self axisViewBounds]];
    }
    return path;
}

- (CMKBezierPath *)pathForXAxisOverlayLabelOutline
{
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    if (self.overlayInteractionTouchActive)
    {
        ChartDataPoint *dataPoint = [self.xAxis dataPointForViewPosition:self.overlayInteractionTouchPosition inViewRect:[self axisViewBounds]];
        path = [self.xAxis pathForXAxisOverlayLabelOutlineForDataPoint:dataPoint inViewRect:[self axisViewBounds]];
    }
    return path;
}


#pragma mark - axis creation


- (void)createAxes
{
    // draw x axis
    if (self.xAxis.model.enabled)
    {
        if (!self.xAxis.model.hidden)
        {
//            self.xAxisShape = [self.xAxis shapeForAxisInViewRect:self.bounds];
            self.xAxisShape = [self.xAxis shapeForAxisInViewRect:[self activeViewBounds]];
        }
    }
    // draw y axis
    if (self.yAxis.model.enabled)
    {
        if (!self.yAxis.model.hidden)
        {
//            self.yAxisShape = [self.yAxis shapeForAxisInViewRect:self.bounds];
            self.yAxisShape = [self.yAxis shapeForAxisInViewRect:[self activeViewBounds]];
        }
    }
}


- (void)createAxisIntersections
{
    CMKTickMarksModel *tickmarksModel = self.xAxis.model.gridlineTickMarks;
    CAShapeLayer *shape = [[CAShapeLayer alloc] init];
    [shape setName:@"intersections"];
    shape.frame = [self activeViewBounds]; //self.bounds;
    shape.lineWidth = tickmarksModel.lineStyle.lineWidth;
    shape.strokeColor = [UIColor colorWithARGB:tickmarksModel.lineStyle.lineColor.colorValue].CGColor;
    if (tickmarksModel.customPath.fillColor)
    {
        shape.fillColor = [UIColor colorWithARGB:tickmarksModel.customPath.fillColor.colorValue].CGColor;
    }
    else
    {
        shape.fillColor = (tickmarksModel.style == CMKTickMarkStyleDot ? shape.strokeColor : nil);
    }

    CMKBezierPath *path = [self pathForAxisIntersections];
    shape.path = path.CGPath;

    self.intersectionsShape = shape;
    [self.layer addSublayer:shape];
}


- (CMKBezierPath *)pathForAxisIntersections
{
    CMKBezierPath *path = [CMKBezierPath bezierPath];
    [self.xAxis enumerateAxisGridlinesForTimeSeries:self.xAxis.series block:^(CGPoint xAxisGridlineViewPointStart, CGPoint xAxisGridlineViewPointEnd, NSString *xAxisLabel, int index) {
        
        [self.yAxis enumerateAxisGridlinesForSeries:self.yAxis.series block:^(CGPoint yAxisGridlineViewPointStart, CGPoint yAxisGridlineViewPointEnd, NSString *yAxisLabel) {
            
            CGPoint p = CGPointMake(xAxisGridlineViewPointStart.x, yAxisGridlineViewPointStart.y);
            //NSLog(@"intersection %0.f,%0.f", p.x, p.y);
            [self.xAxis.model.gridlineTickMarks addTickMarkToPath:path atPoint:p];

        }];
    }];
    return path;
}

#pragma mark - getters

- (ChartXAxis *)xAxisForSeries:(ChartSeries *)series
{
    ChartXAxis *axis = [[ChartXAxis alloc] init];
    axis.delegate = self;
    axis.series = series;
    axis.name = @"Time";
    return axis;
}

- (ChartYAxis *)yAxisForSeries:(ChartSeries *)series
{
    ChartYAxis *axis = [[ChartYAxis alloc] init];
    axis.delegate = self;
    axis.series = series;
    axis.name = series.name;
    return axis;
}


// Create a gradient shape for viewRect, with the specified colours
// path should be closed
//
- (CAGradientLayer *)gradientShapeFromColor:(CMKColor *)fromColor toColor:(CMKColor *)toColor inViewRect:(CGRect)viewRect
{
    CAShapeLayer *mask = [[CAShapeLayer alloc] init];
    mask.frame = viewRect;
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:viewRect];
    mask.path = path.CGPath;
    mask.fillColor = [UIColor blackColor].CGColor;
    
    CAGradientLayer *grad = [[CAGradientLayer alloc] init];
    grad.frame = viewRect;
    grad.colors = @[(id)fromColor.CGColor, (id)toColor.CGColor];
    grad.mask = mask;
    
    return grad;
}



#ifdef OVERRIDE_DRAWRECT
- (void)drawRect:(CGRect)rect
{
#ifdef DEBUG_SHOW_BOUNDS
    // show bounding rects - debug
    CMKBezierPath *boundsPath = [CMKBezierPath bezierPathWithRect:self.bounds];
    boundsPath.lineWidth = 0.5f;
    [[CMKColor redColor] setStroke];
    [boundsPath stroke];

    boundsPath = [CMKBezierPath bezierPathWithRect:[self chartContentRect]];
    boundsPath.lineWidth = 0.5f;
    [[CMKColor blueColor] setStroke];
    [boundsPath stroke];
    
    boundsPath = [CMKBezierPath bezierPathWithRect:[self dataViewBounds]];
    boundsPath.lineWidth = 0.5f;
    [[CMKColor greenColor] setStroke];
    [boundsPath stroke];
#endif
    
//    CGContextRestoreGState(context);
}
#endif


#pragma mark - ChartAxisDelegate

- (CGRect)activeViewBounds
{
    CGRect bounds = self.bounds;
    if (self.layer.presentationLayer != nil)
    {
        bounds = self.layer.presentationLayer.bounds;
        //NSLog(@"animating chartContentRect: %@", NSStringFromCGRect(bounds));
    }
    return bounds;
}

- (CGRect)axisViewBounds
{
    return [self chartContentRect];
}

// this needs to be configurable from JSON
- (CGRect)chartContentRect
{
//    return CGRectInset(self.bounds, 50, 20);
/*
    CGRect bounds = self.bounds;
    if (self.layer.presentationLayer != nil)
    {
        bounds = self.layer.presentationLayer.bounds;
        //NSLog(@"animating chartContentRect: %@", NSStringFromCGRect(bounds));
    }
*/
    CGRect bounds = [self activeViewBounds];
//    return CGRectMake(self.bounds.origin.x+64, self.bounds.origin.y+4,self.bounds.size.width-68,self.bounds.size.height-24);
    return CGRectMake(bounds.origin.x+64, bounds.origin.y+4, bounds.size.width-68, bounds.size.height-24);
}


- (CGRect)dataViewBounds
{
    CGRect innerBounds = [self axisViewBounds];
//    return CGRectMake(innerBounds.origin.x+self.xAxis.padding, innerBounds.origin.y+self.yAxis.padding, innerBounds.size.width-self.yAxis.labelMargin-(self.xAxis.padding*2), innerBounds.size.height-self.xAxis.labelMargin-(self.yAxis.padding*2));
    return CGRectMake(innerBounds.origin.x+self.xAxis.padding, innerBounds.origin.y+self.yAxis.padding, innerBounds.size.width-(self.xAxis.padding*2), innerBounds.size.height-(self.yAxis.padding*2));
}

#pragma mark - helpers

/*
- (ChartDataPoint *)visibleDataPointForDate:(NSDate *)date
{
    

}
*/

#pragma mark - gesture recognizer handlers

#ifdef ENABLE_ZOOM
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer
{

    switch (gestureRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            if ([self.delegate respondsToSelector:@selector(chartViewDidChangeZoomWindow:)])
            {
                [self.delegate chartViewWillChangeZoomWindow:self];
            }
            break;
        case UIGestureRecognizerStateChanged:
        {
            self.currentZoomLevel = _lastZoomLevel * gestureRecognizer.scale;
            if (self.currentZoomLevel < 1.0f) self.currentZoomLevel = 1.0f;
            [self update];
//            if ([self.delegate respondsToSelector:@selector(chartViewDidChangeZoomWindow:)])
//            {
//                [self.delegate chartViewDidChangeZoomWindow:self];
//            }
            break;
        }
        case UIGestureRecognizerStateEnded:
            self.currentZoomLevel = _lastZoomLevel * gestureRecognizer.scale;
            if (self.currentZoomLevel < 1.0f) self.currentZoomLevel = 1.0f;
            [self update];
            _lastZoomLevel = self.currentZoomLevel;
            if ([self.delegate respondsToSelector:@selector(chartViewDidChangeZoomWindow:)])
            {
                [self.delegate chartViewDidChangeZoomWindow:self];
            }
            break;
        default:
            break;
    }
}
#endif

#ifdef ENABLE_PAN
- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            if ([self.delegate respondsToSelector:@selector(chartViewDidChangeZoomWindow:)])
            {
                [self.delegate chartViewWillChangeZoomWindow:self];
            }
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [gestureRecognizer translationInView:self];
            CGFloat offset = [self centreOffsetForTranslation:translation];
            self.currentCentreOffset = _lastCentreOffset + offset;
            [self update];
//            if ([self.delegate respondsToSelector:@selector(chartViewDidChangeZoomWindow:)])
//            {
//                [self.delegate chartViewDidChangeZoomWindow:self];
//            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            CGPoint translation = [gestureRecognizer translationInView:self];
            CGFloat offset = [self centreOffsetForTranslation:translation];
            self.currentCentreOffset = _lastCentreOffset + offset;
            [self update];
            _lastCentreOffset = self.currentCentreOffset;
            if ([self.delegate respondsToSelector:@selector(chartViewDidChangeZoomWindow:)])
            {
                [self.delegate chartViewDidChangeZoomWindow:self];
            }
            break;
        }
        default:
            break;
    }
}
#endif

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint location = [gestureRecognizer locationInView:self];
            self.overlayInteractionTouchPosition = location;
            self.overlayInteractionTouchActive = YES;
            [self updateOverlay];
            //NSLog(@"location: %0.f, %0.f", location.x, location.y);
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint location = [gestureRecognizer locationInView:self];
            //NSLog(@"location: %0.f, %0.f", location.x, location.y);
            self.overlayInteractionTouchPosition = location;
            [self updateOverlay];
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            CGPoint location = [gestureRecognizer locationInView:self];
            //NSLog(@"location: %0.f, %0.f", location.x, location.y);
//            self.overlayInteractionTouchPosition = location;
//            self.overlayInteractionTouchActive = NO;
//            [self updateOverlay];
            
            // show dialog for new vibe
            if ([self.delegate respondsToSelector:@selector(chartView:tapEventOnDataPoint:dataViewLocation:touchLocation:)])
            {
                self.overlayInteractionTouchPosition = location;
//                self.overlayInteractionTouchActive = YES;
//                [self updateOverlay];

                ChartDataPoint *dataPoint = [self.xAxis dataPointForViewPosition:location inViewRect:[self axisViewBounds]];
                // point in data space
//                CGPoint dp = [self.xAxis.series dataSpacePointForDataPoint:dataPoint];
                CGPoint dp = [self.xAxis.series relativeDataSpacePointForDataPoint:dataPoint];
                // convert to point in view
                CGPoint p = [self.xAxis mapPoint:dp toViewRect:[self axisViewBounds]];
                // send to delegate for handling
                [self.delegate chartView:self tapEventOnDataPoint:dataPoint dataViewLocation:p touchLocation:location];

            }
//
//            self.overlayInteractionTouchPosition = location;
//            self.overlayInteractionTouchActive = NO;
//            [self updateOverlay];
            
            break;
        }
        default:
            break;
    }
}


- (void)handleTapGesture:(UITapGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            CGPoint location = [gestureRecognizer locationInView:self];
            //NSLog(@"location: %0.f, %0.f", location.x, location.y);
            if ([self.delegate respondsToSelector:@selector(chartView:tapEventOnDataPoint:dataViewLocation:touchLocation:)])
            {
                self.overlayInteractionTouchPosition = location;
                self.overlayInteractionTouchActive = YES;
                [self updateOverlay];

                ChartDataPoint *dataPoint = [self.xAxis dataPointForViewPosition:location inViewRect:[self axisViewBounds]];
                // point in data space
//                CGPoint dp = [self.xAxis.series dataSpacePointForDataPoint:dataPoint];
                CGPoint dp = [self.xAxis.series relativeDataSpacePointForDataPoint:dataPoint];
                // convert to point in view
                CGPoint p = [self.xAxis mapPoint:dp toViewRect:[self axisViewBounds]];
                // send to delegate for handling
                [self.delegate chartView:self tapEventOnDataPoint:dataPoint dataViewLocation:p touchLocation:location];

            }
            break;
        }
        default:
            break;
    }
}


- (CGFloat)centreOffsetForTranslation:(CGPoint)translation
{
    // get zoom window (assuming no pan until we calculate scale)
    ChartSeries *series = self.xAxis.series;
    CGFloat r0 = [series range];
    CGFloat c0 = r0*0.5f;
    CGFloat centre = c0 - self.currentCentreOffset;
    CMKZoomWindow zoomWindow = [series zoomWindowForZoomLevel:self.currentZoomLevel centre:centre withIndices:NO];
    // calculate pan offset in data range units
    CGFloat wx = [self dataViewBounds].size.width;
    CGFloat xOffsetFraction = translation.x / wx;
    CGFloat xOffset = zoomWindow.range * xOffsetFraction;
    // xOffset is translation.x mapped to data space

//    NSLog(@"xOffset %0.f zoom range %0.f full range %0.f c0 %0.f, _lastCentreOffset %0.f self.currentCentreOffset %0.f", xOffset, zoomWindow.range, [series range], c0, _lastCentreOffset, self.currentCentreOffset);
    
    // lim0 and lim1 define the limits of the zoomed range centre line
    // clamp the xOffset according to these limits
    CGFloat lim0 = c0-(_lastCentreOffset+xOffset)-zoomWindow.range*0.5f;
    if (lim0 < 0)
    {
        //NSLog(@"centre clamp min, lim0 %0.f", lim0);
        return xOffset + lim0;
    }

    CGFloat lim1 = c0-(_lastCentreOffset+xOffset)+zoomWindow.range*0.5f;
    if (lim1 >= r0)
    {
        //NSLog(@"centre clamp max, lim1 %0.f", lim1);
        return xOffset + (lim1-r0);
    }
    // unclamped
    return xOffset;
}

#pragma mark - notifications

- (void)annotationControllerDismissed:(NSNotification *)notification
{
    self.overlayInteractionTouchActive = NO;
    [self updateOverlay];
}





@end
