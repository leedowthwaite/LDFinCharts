//
//  CMKCustomPathModel.h
//  ChartMaker
//
//  Created by Lee Dowthwaite on 08/09/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKSerializableModel.h"
#import "CMKType.h"
#import "CMKMacros.h"
#import "CMKStyleModel.h"

#pragma mark - CMKCustomPathElement

typedef NS_ENUM(int, CMKCustomPathElementType)
{
  CMKCustomPathElementTypeInvalid = -1,
  CMKCustomPathElementTypeMoveToPoint = 0,
  CMKCustomPathElementTypeAddLineToPoint,
  CMKCustomPathElementTypeAddQuadCurveToPoint,
  CMKCustomPathElementTypeAddCurveToPoint,
  CMKCustomPathElementTypeArcWithCenter,
};

@interface CMKCustomPathElement : NSObject

@property (nonatomic, assign) CMKCustomPathElementType type;
@property (nonatomic, strong) NSArray *points;

@end

//typedef void (^CustomPathElementBlock)(CMKCustomPathElementType element, CGFloat x, CGFloat y);
typedef void (^CustomPathElementBlock)(CMKCustomPathElement *element);




#pragma mark - CMKCustomPathModel

@protocol CMKCustomPathModel <NSObject>
@end

@interface CMKCustomPathModel : CMKSerializableModel

/** the path string */
@property (JSON_BACKED_OBJECT) NSString *path;
/** fill color for custom path (omit if no fill required) */
@property (JSON_BACKED_OBJECT) CMKColorModel<Optional> *fillColor;

- (void)addCustomPathsToPath:(CMKBezierPath *)path atPoint:(CGPoint)p0 size:(CGSize)size;


@end
