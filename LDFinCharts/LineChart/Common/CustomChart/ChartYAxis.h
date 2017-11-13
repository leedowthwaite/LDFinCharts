//
//  ChartYAxis.h
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 03/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKType.h"
#import "ChartAxis.h"

@class ChartSeries;
@class ChartDataPoint;

typedef void (^YAxisEnumerationBlock)(CGPoint gridlineViewPointStart, CGPoint gridlineViewPointEnd, NSString *label);

@interface ChartYAxis : ChartAxis

// general axis enumerator
- (void)enumerateAxisGridlinesForSeries:(ChartSeries *)series block:(YAxisEnumerationBlock)block;
// bezier path creation methods
- (CMKBezierPath *)bezierPathForAxisGridlinesForSeries:(ChartSeries *)series major:(BOOL)major;
- (CMKBezierPath *)bezierPathForAxisLabelsForSeries:(ChartSeries *)series;
- (CMKBezierPath *)pathForYAxisOverlayForDataPoint:(ChartDataPoint *)dataPoint inViewRect:(CGRect)viewRect;
- (CMKBezierPath *)pathForYAxisOverlayLabelForDataPoint:(ChartDataPoint *)dataPoint inViewRect:(CGRect)viewRect;
- (CMKBezierPath *)pathForYAxisOverlayLabelOutlineForDataPoint:(ChartDataPoint *)dataPoint inViewRect:(CGRect)viewRect;

@end
