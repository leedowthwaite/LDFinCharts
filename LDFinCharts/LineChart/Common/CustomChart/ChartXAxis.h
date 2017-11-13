//
//  ChartXAxis.h
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 03/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKType.h"
#import "CMKMacros.h"
#import "ChartAxis.h"
#import "CMKAxisGridlineDescriptor.h"

typedef void (^XAxisEnumerationBlock)(CGPoint gridlineViewPointStart, CGPoint gridlineViewPointEnd, NSString *label, int index);
typedef void (^XAxisGridlineDescEnumerationBlock)(CMKAxisGridlineDescriptor *desc);


@class ChartYAxis;
@class ChartDataPoint;

typedef NS_OPTIONS(int, CMKGridlineFlags)
{
    CMKGridlineFlagsMinor = 1<<0,
    CMKGridlineFlagsMajor = 1<<1,
};

typedef NS_ENUM(int, CMKGridlineAlignment)
{
    CMKGridlineAlignmentToDivision,
    CMKGridlineAlignmentToCalendarMonth,
    CMKGridlineAlignmentToQuarter,
    CMKGridlineAlignmentToYear
};

//typedef struct _ChartContiguousPeriodDesc
//{
//    NSInterval
//
//} ChartContiguousPeriodDesc;


@interface ChartXAxis : ChartAxis

// general axis enumerator
- (void)enumerateAxisGridlinesForTimeSeries:(ChartSeries *)series block:(XAxisEnumerationBlock)block;
- (void)enumerateAxisGridlinesForTimeSeries:(ChartSeries *)series major:(BOOL)major block:(XAxisEnumerationBlock)block;

// bezier path creation methods
//- (CMKBezierPath *)bezierPathForAxisGridlinesForTimeSeries:(ChartSeries *)series;
- (CMKBezierPath *)bezierPathForAxisGridlinesForTimeSeries:(ChartSeries *)series major:(BOOL)major;
- (CMKBezierPath *)bezierPathForAxisTickmarksForTimeSeries:(ChartSeries *)series;
- (CMKBezierPath *)bezierPathForAxisLabelsForTimeSeries:(ChartSeries *)series;
//- (CMKBezierPath *)bezierPathForGridlineTickMarksEnumeratedByOtherAxis:(ChartYAxis *)otherAxis series:(ChartSeries *)series;

- (NSTimeInterval)divisionForTimePeriod:(NSTimeInterval)period;
- (BOOL)period:(CGFloat)period isWithinPercent:(CGFloat)percent ofTarget:(CGFloat)target;
- (NSTimeInterval)dateRangeForSeries:(ChartSeries *)series;
- (NSDate *)dateAfterDate:(NSDate *)date moduloInterval:(NSTimeInterval)interval;
- (NSTimeInterval)intervalAfterDate:(NSDate *)date moduloInterval:(NSTimeInterval)interval;

- (CMKBezierPath *)pathForXAxisOverlayAtViewPosition:(CGPoint)point;
- (CMKBezierPath *)pathForXAxisOverlayIntersectionAtViewPosition:(CGPoint)point;
- (double)dataSpacePositionForX:(CGFloat)x inViewRect:(CGRect)viewRect;
- (ChartDataPoint *)dataPointForViewPosition:(CGPoint)point inViewRect:(CGRect)viewRect;
- (CMKBezierPath *)pathForXAxisOverlayLabelForDataPoint:(ChartDataPoint *)dataPoint inViewRect:(CGRect)viewRect;
- (CMKBezierPath *)pathForXAxisOverlayLabelOutlineForDataPoint:(ChartDataPoint *)dataPoint inViewRect:(CGRect)viewRect;

@end
