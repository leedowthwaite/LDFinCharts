//
//  CMKSerializableModel.h
//  ChartMaker
//
//  Created by Lee Dowthwaite on 29/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"

@interface CMKSerializableModel : JSONModel

+ (CMKSerializableModel *)modelWithData:(NSData *)data;
+ (CMKSerializableModel *)modelWithJSONString:(NSString *)json;


@end
