//
//  ChartAxisModel.h
//  ChartMaker
//
//  Created by Lee Dowthwaite on 29/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKSerializableModel.h"
#import "CMKMacros.h"
#import "CMKStyleModel.h"
#import "JSONValueTransformer+CGSize.h"
#import "CMKCustomPathModel.h"
#import "CMKTickMarksModel.h"

typedef NS_ENUM(int, CMKAxisCategory)
{
    CMKAxisCategoryNone = -1,
    CMKAxisCategoryOrdinal = 0,
    CMKAxisCategoryTimeSeries
};

typedef NS_ENUM(int, CMKAxisPosition)
{
    CMKAxisPositionNone = 0,
    CMKAxisPositionBottom = 1,
    CMKAxisPositionTop = 2,
    CMKAxisPositionLeft = 3,
    CMKAxisPositionRight = 4
};

typedef NS_ENUM(int, CMKLabelsPosition)
{
    CMKLabelsPositionOutside = 0,
    CMKLabelsPositionInside = 1
};

#pragma mark - ChartAxisModel

@interface ChartAxisModel : CMKSerializableModel

/** determine whether the axis is hidden */
@property (JSON_BACKED_SCALAR) BOOL hidden;
/** is this even used? */
@property (JSON_BACKED_SCALAR) BOOL enabled;
/** axis category, e.g. ordinal or time series */
@property (JSON_BACKED_SCALAR) CMKAxisCategory category;
/** the position of the axis relative to the axis view bounds */
@property (JSON_BACKED_SCALAR) CMKAxisPosition position;
/** additional padding in this axis between the axis line and the data area, e.g. y-axis padding to leave a gap between the extremes of the data and the top/bottom edges of the chart */
@property (JSON_BACKED_SCALAR) CGFloat padding;
/** the additional space between the axis labels and the axis line. Positive for more space, negative to overlap */
@property (JSON_BACKED_SCALAR) CGFloat labelMargin;
/** a StyleModel object describing the axis line style */
@property (JSON_BACKED_OBJECT) CMKLineStyleModel *lineStyle;
/** gridline bleed beyond the near (axis) end. Zero to end gridline at axis, positive to extend beyond axis, negative to truncate it before axis */
@property (JSON_BACKED_SCALAR) CGFloat gridlinesNearBleed;
/** gridline bleed beyond the far (opposite from axis) end. Zero to end gridline at axis, positive to extend beyond axis, negative to truncate it before axis */
@property (JSON_BACKED_SCALAR) CGFloat gridlinesFarBleed;
/** a StyleModel object describing the gridlines' style */
@property (JSON_BACKED_OBJECT) CMKLineStyleModel<Optional> *gridlinesStyle;
/** a StyleModel object describing the major gridlines' style */
@property (JSON_BACKED_OBJECT) CMKLineStyleModel<Optional> *majorGridlinesStyle;
/** label position - inside or outside the axis line */
@property (JSON_BACKED_SCALAR) CMKLabelsPosition labelsPosition;
/** label format string */
@property (JSON_BACKED_OBJECT) NSString *labelsFormat;
/* a StyleModel object describing the axis labels' text style */
@property (JSON_BACKED_OBJECT) CMKStyleModel *labelsStyle;

@property (JSON_BACKED_OBJECT) NSArray<CMKTickMarksModel, Optional> *axisTickMarks;
@property (JSON_BACKED_OBJECT) CMKTickMarksModel<Optional> *gridlineTickMarks;

@end
