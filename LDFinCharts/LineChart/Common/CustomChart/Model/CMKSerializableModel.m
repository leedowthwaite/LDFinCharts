//
//  CMKSerializableModel.m
//  ChartMaker
//
//  Created by Lee Dowthwaite on 29/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKSerializableModel.h"

@implementation CMKSerializableModel

+ (CMKSerializableModel *)modelWithData:(NSData *)data
{
    NSError *error = nil;
    CMKSerializableModel *model = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error];
    assert(!error);
    return model;
}

+ (CMKSerializableModel *)modelWithJSONString:(NSString *)json
{
    NSError *error = nil;
    CMKSerializableModel *model = [[CMKSerializableModel alloc] initWithString:json error:&error];
    if (error)
    {
        NSLog(@"Error deserializing model.\nMessage: %@.\nJSON: %@", [error localizedDescription], json);
        assert(!error);
    }
    //NSLog(@"model %@", model);
    return model;
}

@end
