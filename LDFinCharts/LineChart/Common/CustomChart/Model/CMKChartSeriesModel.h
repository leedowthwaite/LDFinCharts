//
//  CMKChartSeriesModel.h
//  ChartMaker
//
//  Created by Lee Dowthwaite on 25/08/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKSerializableModel.h"
#import "CMKMacros.h"
#import "CMKStyleModel.h"
#import "CMKColorModel.h"
#import "CMKTickMarksModel.h"

@protocol CMKChartSeriesModel <NSObject>
@end

@interface CMKChartSeriesModel : CMKSerializableModel

typedef NS_ENUM(int, CMKSeriesCategory)
{
    CMKSeriesCategoryNone = -1,
    CMKSeriesCategoryLine = 0,
    CMKSeriesCategoryCandle = 1,
    CMKSeriesCategoryOHLC = 2,
    CMKSeriesCategoryHistogram = 3
};

typedef NS_ENUM(int, CMKSeriesSmoothingAlgorithm)
{
    CMKSeriesSmoothingAlgorithmNone = 0,
    CMKSeriesSmoothingAlgorithmQuad = 1,
    CMKSeriesSmoothingAlgorithmSpline = 2,
};

@property (JSON_BACKED_SCALAR) BOOL hidden;
@property (JSON_BACKED_SCALAR) BOOL enabled;
@property (JSON_BACKED_SCALAR) CMKSeriesCategory category;
@property (JSON_BACKED_SCALAR) CMKSeriesSmoothingAlgorithm smoothingAlgorithm;
@property (JSON_BACKED_OBJECT) CMKLineStyleModel *lineStyle;
@property (JSON_BACKED_OBJECT) NSArray<CMKColorModel, Optional> *fillColors;
@property (JSON_BACKED_OBJECT) NSArray<CMKTickMarksModel, Optional> *dataPointMarks;

@end
