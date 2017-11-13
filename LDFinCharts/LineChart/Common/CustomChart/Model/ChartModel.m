//
//  ChartModel.m
//  ChartMaker
//
//  Created by Lee Dowthwaite on 31/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "ChartModel.h"

@implementation ChartModel

+ (ChartModel *)modelWithJSONString:(NSString *)json
{
    NSError *error = nil;
    ChartModel *model = [[ChartModel alloc] initWithString:json error:&error];
    if (error)
    {
        NSLog(@"Error deserializing model.\nMessage: %@.\nJSON: %@", [error localizedDescription], json);
        assert(!error);
    }
    //NSLog(@"model %@", model);
    return model;
}

@end
