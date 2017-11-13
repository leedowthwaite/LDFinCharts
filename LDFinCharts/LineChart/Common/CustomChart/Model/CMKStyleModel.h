//
//  StyleModel.h
//  ChartMaker
//
//  Created by Lee Dowthwaite on 02/04/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKSerializableModel.h"
#import "CMKType.h"
#import "CMKMacros.h"
#import "CMKColorModel.h"

typedef NS_ENUM(int, CMKSimpleLineStyle)
{
    CMKLineStyleNone = -1,
    CMKLineStyleSolid = 0,
    CMKLineStyleDashed = 1,     // dashed (5,5)
    CMKLineStyleDotted = 2      // dotted (2,2)

};

typedef NS_ENUM(int, CMKLineEndCapStyle)
{
    CMKLineEndCapStyleNone = -1,
    CMKLineEndCapStyleButt = 0,
    CMKLineEndCapStyleSquare = 1,
    CMKLineEndCapStyleRound = 2
};


typedef NS_ENUM(int, CMKLineJoinStyle)
{
    CMKLineJoinStyleNone = -1,
    CMKLineJoinStyleMiter = 0,
    CMKLineJoinStyleBevel = 1,
    CMKLineJoinStyleRound = 2
};

@protocol CMKLineStyleModel <NSObject>
@end

// line style model
@interface CMKLineStyleModel : CMKSerializableModel

@property (JSON_BACKED_OBJECT) CMKColorModel<Optional> *lineColor;
@property (JSON_BACKED_SCALAR) CMKSimpleLineStyle simpleLineStyle;
@property (JSON_BACKED_SCALAR) NSString<Optional> *dashPattern;
@property (JSON_BACKED_SCALAR) CMKLineEndCapStyle lineEndCapStyle;
@property (JSON_BACKED_SCALAR) CMKLineJoinStyle lineJoinStyle;
@property (JSON_BACKED_SCALAR) CGFloat lineWidth;
@property (JSON_BACKED_SCALAR) BOOL hidden;

// translations
- (NSString * const)lineEndCapStyleAsCAString;
- (NSString * const)lineJoinStyleAsCAString;
- (NSArray *)dashPatternAsArray;

@end


// general style model
//
@protocol CMKStyleModel <NSObject>
@end

@interface CMKStyleModel : CMKSerializableModel

/*
            "color": "#ff000000",
            "lineThickness": 1.0,
            "dashPattern": "(1,5)",
            "font": "HelveticaNeue-Bold",
*/

@property (JSON_BACKED_OBJECT) NSString *rgbColorCode;
@property (JSON_BACKED_OBJECT) NSString *fontName;
@property (JSON_BACKED_SCALAR) CGFloat fontSize;
@property (JSON_BACKED_SCALAR) CGFloat lineWidth;
//@property (JSON_BACKED_SCALAR) CMKLineStyleModel<Optional> *lineStyle;
@property (JSON_BACKED_SCALAR) BOOL hidden;

@property (nonatomic, readonly) unsigned int colorValue;

@end
