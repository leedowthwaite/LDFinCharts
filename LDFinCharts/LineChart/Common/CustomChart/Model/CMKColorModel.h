//
//  CMKColorModel.h
//  ChartMaker
//
//  Created by Lee Dowthwaite on 02/04/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKSerializableModel.h"
#import "CMKMacros.h"
#import "CMKColor+CMKExtensions.h"

@protocol CMKColorModel <NSObject>
@end

@interface CMKColorModel : CMKSerializableModel

/*
            "color": "#ff000000",
*/

@property (JSON_BACKED_OBJECT) NSString *rgbColorCode;

@property (nonatomic, readonly) unsigned int colorValue;
@property (nonatomic, readonly) CMKColor *color;

@end
