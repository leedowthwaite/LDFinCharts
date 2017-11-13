//
//  ChartView.h
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 26/02/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKType.h"
#import "ChartAxis.h"
#import "ChartModel.h"

@class ChartView;
@class ChartSeries;
@class ChartDataPoint;
@class ChartXAxis;
@class ChartYAxis;

extern NSString * const LDChartViewErrorDomain;


typedef NS_ENUM(NSInteger, LDChartViewErrorCode)
{
    LDChartViewErrorNoSourceData,
    LDChartViewErrorNoModel,
    LDChartViewErrorNoSeries,
    LDChartViewErrorMissingDataPoints,
    LDChartViewErrorNilSeries,
    LDChartViewErrorArrayOutOfBounds,
    LDChartViewErrorRangeZero,
};

@protocol ChartViewDataSource <NSObject>
- (NSInteger)numberOfSeriesForChartView:(ChartView *)chartView;
- (NSInteger)chartView:(ChartView *)chartView numberOfDataPointsForSeriesIndex:(NSInteger)seriesIndex;
- (ChartDataPoint *)chartView:(ChartView *)chartView seriesIndex:(NSInteger)seriesIndex dataPointForIndex:(NSInteger)dataPointIndex;
- (ChartSeries *)chartView:(ChartView *)chartView seriesForIndex:(NSInteger)seriesIndex;
@end

@protocol ChartViewDelegate <NSObject>
@optional
- (BOOL)chartView:(ChartView *)chartView tapEventOnDataPoint:(ChartDataPoint *)dataPoint dataViewLocation:(CGPoint)dataViewLocation touchLocation:(CGPoint)touchLocation;
- (void)chartViewWillChangeZoomWindow:(ChartView *)chartView;
- (void)chartViewDidChangeZoomWindow:(ChartView *)chartView;
@end

@interface ChartView : CMKView <ChartAxisDelegate>

@property (nonatomic, strong) ChartModel *model;
@property (nonatomic, strong) ChartXAxis *xAxis;
@property (nonatomic, strong) ChartYAxis *yAxis;
@property (nonatomic, strong) CMKColor *lineColor;
@property (nonatomic, strong) CMKColor *labelColor;
@property (nonatomic, weak) id<ChartViewDataSource> dataSource;
@property (nonatomic, weak) id<ChartViewDelegate> delegate;
@property (nonatomic, assign) CGFloat currentZoomLevel;
@property (nonatomic, assign) CGFloat currentCentreOffset;
@property (nonatomic, readonly) CMKZoomWindow zoomWindow;

- (void)reloadData:(NSError * __autoreleasing *)errorResult;
- (void)update;
- (void)setGradientMaskForRect:(CGRect)rect;
- (void)removeGradientMask;

@end
