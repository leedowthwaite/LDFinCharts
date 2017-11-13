//
//  ChartContiguousPeriodDescriptor.h
//  stockvibe
//
//  Created by Lee Dowthwaite on 05/02/2016.
//  Copyright © 2016 Echelon Developments Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChartContiguousPeriodDescriptor : NSObject

@property (nonatomic, assign) NSDate *startDate;
@property (nonatomic, assign) NSTimeInterval nextStartEpoch;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) int firstDataPointIndex;
@property (nonatomic, assign) int lastDataPointIndex;

@end
