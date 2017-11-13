//
//  CMKTickMarksModel.h
//  ChartMaker
//
//  Created by Lee Dowthwaite on 09/09/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKSerializableModel.h"
#import "CMKMacros.h"
#import "CMKStyleModel.h"
#import "JSONValueTransformer+CGSize.h"
#import "CMKCustomPathModel.h"

typedef NS_OPTIONS(int, CMKTickmarksPosition)
{
    CMKTickmarksPositionNear = 0x0001,
    CMKTickmarksPositionFar = 0x0002,
    CMKTickmarksPositionCenter = 0x0000,
    CMKTickmarksPositionInside = 0x0004,
    CMKTickmarksPositionOutside = 0x0008,
};

typedef NS_ENUM(int, CMKTickMarkStyle)
{
    CMKTickMarkStyleNone = 0,
    CMKTickMarkStyleDot = 1,
    CMKTickMarkStyleVerticalMark = 2,
    CMKTickMarkStyleHorizontalMark = 3,
    CMKTickMarkStyleCross = 4,
    CMKTickMarkStyleCustomPath = 5,
};

#pragma mark - CMKTickMarksModel

@protocol CMKTickMarksModel <NSObject>
@end

@interface CMKTickMarksModel : CMKSerializableModel

/** an optional tag, to determine how to cascade the style */
@property (JSON_BACKED_OBJECT) NSString<Optional> *tag;
/** determine whether the tickmarks are hidden */
@property (JSON_BACKED_SCALAR) BOOL hidden;
/** tickmark style */
@property (JSON_BACKED_SCALAR) CMKTickMarkStyle style;
/** tickmark size */
@property (JSON_BACKED_SCALAR) CGSize size; // like so in JSON:   "size": "{20,10}"
/* tickmarks position flags */
@property (JSON_BACKED_SCALAR) CMKTickmarksPosition position;
/** a StyleModel object describing the tickmark line style */
@property (JSON_BACKED_OBJECT) CMKLineStyleModel<Optional> *lineStyle;
/** a custom path, in string form */
@property (JSON_BACKED_OBJECT) CMKCustomPathModel *customPath;

- (void)addTickMarkToPath:(CMKBezierPath *)path atPoint:(CGPoint)p;
+ (void)addTickMarkToPath:(CMKBezierPath *)path atPoint:(CGPoint)p size:(CGSize)size withStyle:(CMKTickMarkStyle)style;
+ (void)addCrossToPath:(CMKBezierPath *)path atPoint:(CGPoint)p size:(CGSize)size;

@end


