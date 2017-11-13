//
//  ChartAxis.h
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 03/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKType.h"
#import "ChartAxisModel.h"
//#import "ChartSeries.h"
/*
typedef enum
{
    AxisCategoryNone = -1,
    AxisCategoryOrdinal = 0,
    AxisCategoryTimeSeries
} AxisCategory;

typedef enum
{
    AxisPositionNone = -1,
    AxisPositionTop = 0,
    AxisPositionBottom,
    AxisPositionLeft,
    AxisPositionRight
} AxisPosition;
*/


@protocol ChartAxisDelegate <NSObject>
- (CGRect)presentingViewBounds;
- (CGRect)axisViewBounds;
- (CGRect)dataViewBounds;
@end

@class ChartSeries;

@interface ChartAxis : NSObject

// the underlying serializable model
@property (nonatomic, strong) ChartAxisModel *model;
// the delegate
@property (nonatomic, weak) id<ChartAxisDelegate> delegate;
// the series represented by this axis
@property (nonatomic, strong) ChartSeries *series;
// axis name
@property (nonatomic, strong) NSString *name;

@property (nonatomic, assign) CMKZoomWindow *zoomWindow;

// legacy properties - should be moved to model
@property (nonatomic, assign) BOOL autoGridlines;
@property (nonatomic, assign) BOOL labelsVisible;


// derived properties
@property (nonatomic, assign) double start;
@property (nonatomic, assign) double span;
@property (nonatomic, assign) double division;
@property (nonatomic, assign) int ndiv;
@property (nonatomic, readonly) CGFloat viewRangeX;
@property (nonatomic, readonly) CGFloat viewRangeY;
// properties that are derived from model
@property (nonatomic, readonly) CGFloat padding;
@property (nonatomic, readonly) CGFloat labelMargin;


// Bezier paths for the axis components
@property (nonatomic, strong) CMKBezierPath *axisBezierPath;
@property (nonatomic, strong) CMKBezierPath *gridlinesBezierPath;
@property (nonatomic, strong) CMKBezierPath *tickmarksBezierPath;
@property (nonatomic, strong) CMKBezierPath *labelsBezierPath;

// abstract interface
+ (ChartAxis *)axisWithJSONDict:(NSDictionary *)json;
+ (ChartAxis *)axisWithModel:(ChartAxisModel *)model;

- (id)initWithModel:(ChartAxisModel *)model;
- (void)configureFromModel:(ChartAxisModel *)model;
- (CMKBezierPath *)bezierPathForAxisForSeries:(ChartSeries *)series;
//- (CMKBezierPath *)bezierPathForAxisGridlinesForSeries:(ChartSeries *)series;
- (CMKBezierPath *)bezierPathForAxisGridlinesForSeries:(ChartSeries *)series major:(BOOL)major;
- (CMKBezierPath *)bezierPathForAxisTickmarksForSeries:(ChartSeries *)series;

//
- (CGFloat)viewRangeX;
- (CGFloat)viewRangeY;
- (CMKBezierPath *)pathForXAxis;
- (CMKBezierPath *)pathForYAxis;
- (CGPoint)mapPoint:(CGPoint)dp toViewRect:(CGRect)viewRect;
- (CAShapeLayer *)shapeForAxisInViewRect:(CGRect)viewRect;
- (CAShapeLayer *)updatePathsForAxisShape:(CAShapeLayer *)shape;
- (void)setLinePatternOnPath:(CMKBezierPath *)path forStyle:(CMKLineStyleModel *)style;

- (void)addSeries:(ChartSeries *)series;

- (NSString *)formattedStringWithFloat:(CGFloat)val;
- (NSString *)formattedStringWithNumber:(NSNumber *)val;
+ (int)scientificExponentForRawValue:(CGFloat)value;
+ (NSString *)abbreviatedStringForRawValue:(CGFloat)value;


@end
