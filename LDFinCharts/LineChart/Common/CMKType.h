//
//  CMKType.h
//  ChartMaker
//
//  Created by Lee Dowthwaite on 13/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//



//# warning Building for iOS/simulator
# import <Foundation/Foundation.h>
# import <UIKit/UIKit.h>

/////////////////////////////
//      iOS types
/////////////////////////////

typedef struct _CMKZoomWindow
{
    CGFloat zoomLevel;
    double startValue, endValue, range;
    int startIndex, endIndex, spanPoints;
    CGFloat clampMin, clampMax;

} CMKZoomWindow;



// cannot extend typedef'ed object types, so use preprocessor instead
//typedef UIColor CMKColor;
#define CMKColor UIColor

//typedef UIBezierPath CMKBezierPath;
#define CMKBezierPath UIBezierPath
typedef UIFont CMKFont;
typedef UIView CMKView;
//#define CMKView UIView

/////////////////////////////
//      iOS macros
/////////////////////////////

# define BZPATH                         CMKBezierPath
# define BZPATH_MOVE_TO(path,point)     [path moveToPoint:point]
# define BZPATH_LINE_TO(path,point)     [path addLineToPoint:point]
# define BZPATH_ARC_WITH_CENTER(path,point,r)   [path addArcWithCenter:(point) radius:(r) startAngle:0 endAngle:(2*M_PI) clockwise:YES]
# define BZPATH_APPEND(path,subpath)    [path appendPath:subpath]


