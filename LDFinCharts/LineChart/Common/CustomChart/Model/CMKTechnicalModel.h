//
//  CMKTechnicalModel.h
//  stockvibe
//
//  Created by Lee Dowthwaite on 10/03/2016.
//  Copyright © 2016 ASwift.Team. All rights reserved.
//

#import "CMKSerializableModel.h"
#import "CMKMacros.h"
#import "CMKStyleModel.h"
#import "CMKColorModel.h"

@class ChartSeries;

@interface CMKTechnicalModel : CMKSerializableModel

typedef NS_ENUM(int, CMKTechnicalCategory)
{
    CMKTechnicalCategoryNone = -1,
    CMKTechnicalCategorySMA = 0,
    CMKTechnicalCategoryEMA,
    CMKTechnicalCategorySR,
    CMKTechnicalCategoryTrendline,
    CMKTechnicalCategoryBollinger,
    CMKTechnicalCategoryRSI,
    CMKTechnicalCategoryMACD,
    CMKTechnicalCategoryCustom
};

@property (JSON_BACKED_OBJECT) NSString *name;
@property (JSON_BACKED_OBJECT) NSString<Optional> *displayName;
@property (JSON_BACKED_OBJECT) ChartSeries *sourceSeries;
@property (JSON_BACKED_SCALAR) CMKTechnicalCategory technicalCategory;
@property (JSON_BACKED_SCALAR) BOOL enabled;
@property (JSON_BACKED_OBJECT) CMKColorModel<Optional> *lineColor;
@property (JSON_BACKED_OBJECT) CMKStyleModel<Optional> *lineStyle;

// properties specific to CMKTechnicalCategory
@property (JSON_BACKED_SCALAR) int period;
// add further reasonably generic properties here, or subclass for more obscure/custom stuff

@end
