//
//  ChartModel.h
//  ChartMaker
//
//  Created by Lee Dowthwaite on 31/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKSerializableModel.h"
#import "ChartAxisModel.h"
#import "CMKChartSeriesModel.h"
#import "CMKTechnicalModel.h"
#import "CMKMacros.h"

@interface ChartModel : CMKSerializableModel

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) ChartAxisModel *xAxisModel;
@property (nonatomic, strong) ChartAxisModel *yAxisModel;
@property (nonatomic, strong) NSArray<CMKChartSeriesModel, Optional> *seriesModels;

+ (ChartModel *)modelWithJSONString:(NSString *)json;

@end
