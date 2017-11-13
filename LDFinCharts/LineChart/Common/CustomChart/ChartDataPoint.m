//
//  ChartDataPoint.m
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 26/02/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "ChartDataPoint.h"

#pragma mark - ChartDataValue


@interface ChartDataValue()
@property (nonatomic, strong) id internalValue;
@end
@implementation ChartDataValue
@end

@interface ChartNumericDataValue()
{
}
@end

@implementation ChartNumericDataValue
+ (ChartDataValue *)valueWithNumber:(NSNumber *)value
{
    ChartNumericDataValue *data = [[ChartNumericDataValue alloc] init];
    [data setInternalValue:value];
    return data;
}

- (NSNumber *)valueAsNumber
{
    return (NSNumber *)self.internalValue;
}

- (CGFloat)valueAsFloat
{
    return [((NSNumber *)self.internalValue) floatValue];
}
@end

@implementation ChartTimeDataValue
+ (ChartDataValue *)valueWithDate:(NSDate *)date
{
    ChartTimeDataValue *data = [[ChartTimeDataValue alloc] init];
    [data setInternalValue:date];
    return data;
}

- (NSDate *)valueAsDate
{
    return (NSDate *)self.internalValue;
}

+ (ChartDataValue *)valueWithEpochTime:(NSTimeInterval)epochTime
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:epochTime];
    return [self valueWithDate:date];
}

- (NSTimeInterval)valueAsEpochTime
{
    return [[self valueAsDate] timeIntervalSince1970];
}
@end


#pragma mark - ChartDataPoint

@implementation ChartDataPoint

@end


@implementation ChartTimeSeriesDataPoint
+ (ChartTimeSeriesDataPoint *)timeSeriesDataPointWithDate:(NSDate *)date andValue:(NSNumber *)value
{
    ChartTimeSeriesDataPoint *dataPoint = [[ChartTimeSeriesDataPoint alloc] init];
    dataPoint.xValue = [ChartTimeDataValue valueWithDate:date];
    dataPoint.yValue = [ChartNumericDataValue valueWithNumber:value];
//    dataPoint.contiguousStart = NO;
    return dataPoint;
}
@end

@implementation ChartCandleDataPoint

//+ (ChartCandleDataPoint *)timeSeriesDataPointWithDate:(NSDate *)date open:(NSNumber *)open close:(NSNumber *)close high:(NSNumber *)high low:(NSNumber *)low
+ (ChartCandleDataPoint *)chartCandleDataPointWithDate:(NSDate *)date open:(NSNumber *)open close:(NSNumber *)close high:(NSNumber *)high low:(NSNumber *)low
{
    ChartCandleDataPoint *dataPoint = [[ChartCandleDataPoint alloc] init];
    dataPoint.xValue = [ChartTimeDataValue valueWithDate:date];
    dataPoint.openValue = [ChartNumericDataValue valueWithNumber:open];
    dataPoint.closeValue = [ChartNumericDataValue valueWithNumber:close];
    dataPoint.highValue = [ChartNumericDataValue valueWithNumber:high];
    dataPoint.lowValue = [ChartNumericDataValue valueWithNumber:low];
    return dataPoint;
}

// closeValue is actually an alias for yValue. This allows existing time series processing code to work unchanged on close value.

- (void)setCloseValue:(ChartDataValue *)closeValue
{
    self.yValue = closeValue;
}

- (ChartDataValue *)closeValue
{
    return self.yValue;
}

@end


@implementation ChartXYDataPoint
@end
