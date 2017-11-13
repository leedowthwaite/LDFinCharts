//
//  ChartSeries.h
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 26/02/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKType.h"
#import "ChartDataPoint.h"

@class ChartSeries;
@class CMKChartSeriesModel;
@class CMKLineStyleModel;
@class CMKTickMarksModel;
@class ChartXAxis;
@class ChartYAxis;
@class ChartContiguousPeriodDescriptor;

NS_ASSUME_NONNULL_BEGIN

typedef void (^ChartSeriesEnumerationBlock)(ChartDataPoint *dataPoint);
typedef void (^ChartSeriesContiguousPeriodEnumerationBlock)(ChartContiguousPeriodDescriptor *desc, BOOL *stop);
typedef void (^ChartSeriesCandleGeneratorBlock)(ChartCandleDataPoint *dataPoint, CMKBezierPath *path);


//@protocol ChartViewDataSource <NSObject>
//- (ChartDataPoint *)chartSeries:(ChartSeries *)series dataPointForIndex:(NSInteger)index;
//@end


@interface ChartSeries : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray *dataPoints;
@property (nonatomic, readonly) CGFloat maxY;
@property (nonatomic, readonly) CGFloat minY;
@property (nonatomic, readonly) NSDate *maxTimeX;
@property (nonatomic, readonly) NSDate *minTimeX;
@property (nonatomic, readonly) NSInteger count;
@property (nonatomic, readonly) NSTimeInterval meanInterval;
@property (nonatomic, readonly) BOOL isIntraday;
@property (nonatomic, weak) ChartSeries *derivedFrom;
// the underlying serializable model
@property (nonatomic, strong) CMKChartSeriesModel *model;
// the linked axes
@property (nonatomic, strong) ChartXAxis *xAxis;
@property (nonatomic, strong) ChartYAxis *yAxis;

- (void)invalidate;
- (ChartDataPoint * _Nullable)dataPointAtIndex:(NSInteger)index;
- (void)addDataPoint:(ChartDataPoint *)dataPoint;
- (void)addSeries:(ChartSeries *)series;
- (NSInteger)count;
- (NSTimeInterval)dateRange;
- (double)range;

// mapping
- (CMKZoomWindow)zoomWindowForZoomLevel:(CGFloat)zoomLevel centre:(double)centre;
- (CMKZoomWindow)zoomWindowForZoomLevel:(CGFloat)zoomLevel centre:(double)centre withIndices:(BOOL)findIndices;

- (CGPoint)dataSpacePointForDataPoint:(ChartDataPoint *)dataPoint;
- (CGPoint)relativeDataSpacePointForDataPoint:(ChartDataPoint *)dataPoint;
- (int)nearestDataPointIndexForXValue:(double)xValue;
- (int)dataPointIndexForStartXValue:(double)xValue;
- (int)dataPointIndexForStartXValueRelative:(double)xValue;
- (ChartDataPoint * _Nullable)dataPointForDateValue:(NSDate *)date;
- (CGPoint)mapPoint:(CGPoint)point toViewRect:(CGRect)rect;
- (CGPoint)mapPoint:(CGPoint)point toViewRect:(CGRect)rect zoomLevel:(CGFloat)zoomLevel centre:(NSInteger)centre;
- (CGPoint)mapPoint:(CGPoint)point toViewRect:(CGRect)rect zoomWindow:(CMKZoomWindow)zoomWindow;
- (CGFloat)mapViewX:(CGFloat)viewX fromViewRect:(CGRect)rect;
- (CGFloat)mapViewX:(CGFloat)viewX fromViewRect:(CGRect)rect zoomWindow:(CMKZoomWindow)zoomWindow;
- (NSArray *)timeSeriesHourlyIndices;

// enumeration
- (void)enumerateWithBlock:(ChartSeriesEnumerationBlock)block;
- (void)enumerateContiguousPeriodsWithBlock:(ChartSeriesContiguousPeriodEnumerationBlock)block;
// coniguity
- (void)processGaps;

// Bezier path generation
- (void)generateCandleBezierPathsInViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre block:(ChartSeriesCandleGeneratorBlock)block;
- (CMKBezierPath *)candleBezierPathInViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre;
- (CMKBezierPath *)bezierPathInViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre;
- (CMKBezierPath *)rawBezierPathInViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre;
- (CMKBezierPath *)quadSmoothedBezierPathInViewRect:(CGRect)viewRect;
- (CMKBezierPath *)splineSmoothedBezierPathWithGranularity:(NSInteger)granularity inViewRect:(CGRect)viewRect;
- (CMKBezierPath *)closedPathForPath:(CMKBezierPath *)path inViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre;
- (CMKBezierPath *)dataPointMarksBezierPathForModel:(CMKTickMarksModel *)model inViewRect:(CGRect)viewRect zoomLevel:(CGFloat)zoomLevel centre:(double)centre;
// shapes for Bezier path
- (CAShapeLayer *)maskForPath:(CMKBezierPath *)path inViewRect:(CGRect)viewRect;
- (CAGradientLayer *)gradientShapeForPath:(CMKBezierPath *)path fromColor:(CMKColor *)fromColor toColor:(CMKColor *)toColor inViewRect:(CGRect)viewRect;
- (CAGradientLayer *)gradientShapeForPath:(CMKBezierPath *)path colors:(NSArray *)colors inViewRect:(CGRect)viewRect;
- (CAGradientLayer *)gradientShapeForPath:(CMKBezierPath *)path inViewRect:(CGRect)viewRect;
- (CAShapeLayer *)lineShapeForPath:(CMKBezierPath *)path inViewRect:(CGRect)viewRect;
//- (CAShapeLayer *)dataPointsShapeForPath:(CMKBezierPath *)path inViewRect:(CGRect)viewRect;
- (CAShapeLayer *)dataPointsShapeForModel:(CMKTickMarksModel *)model withPath:(UIBezierPath *)path tag:(NSString *)tag inViewRect:(CGRect)viewRect;
// line patterns
+ (void)setLinePatternOnPath:(CMKBezierPath *)path;
+ (void)setDashPatternOnShape:(CAShapeLayer *)shape forStyle:(CMKLineStyleModel *)style;
// helpers
+ (ChartSeries *)emaSeriesFromSeries:(ChartSeries *)series withPeriod:(int)period;

@end

NS_ASSUME_NONNULL_END

