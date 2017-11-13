//
//  CMKChartConfigurationController.h
//  ChartMaker
//
//  Created by Lee Dowthwaite on 29/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMKSerializableModel.h"
#import "ChartModel.h"

@interface CMKChartConfigurationController : NSObject

+ (ChartModel *)loadModelFromResourceFile:(NSString *)filename;

@end
