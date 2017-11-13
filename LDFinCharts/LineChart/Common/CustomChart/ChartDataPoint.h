//
//  ChartDataPoint.h
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 26/02/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKType.h"

#pragma mark - ChartDataValue class cluster

@interface ChartDataValue: NSObject
- (NSNumber *)valueAsNumber;
+ (ChartDataValue *)valueWithNumber:(NSNumber *)value;
- (NSDate *)valueAsDate;
+ (ChartDataValue *)valueWithDate:(NSDate *)date;
- (NSTimeInterval)valueAsEpochTime;
+ (ChartDataValue *)valueWithEpochTime:(NSTimeInterval)epochTime;
- (CGFloat)valueAsFloat;
+ (ChartDataValue *)valueWithFloat:(CGFloat)value;
@end

@interface ChartNumericDataValue : ChartDataValue
@end

@interface ChartTimeDataValue : ChartDataValue
@end


#pragma mark - ChartDataPoint class hierarchy

// abstract data point superclass
//
@interface ChartDataPoint : NSObject
@property (nonatomic, strong) ChartDataValue *yValue;
@property (nonatomic, strong) ChartDataValue *xValue;
@property (nonatomic, strong) ChartDataValue *xValueRelative;
//@property (nonatomic, assign) BOOL contiguousStart;
@end

// concrete subclasses
//

@interface ChartTimeSeriesDataPoint : ChartDataPoint
+ (ChartTimeSeriesDataPoint *)timeSeriesDataPointWithDate:(NSDate *)date andValue:(NSNumber *)value;
@end


@interface ChartCandleDataPoint : ChartTimeSeriesDataPoint
@property (nonatomic, strong) ChartDataValue *openValue;
@property (nonatomic, strong) ChartDataValue *closeValue;
@property (nonatomic, strong) ChartDataValue *highValue;
@property (nonatomic, strong) ChartDataValue *lowValue;
//+ (ChartCandleDataPoint *)timeSeriesDataPointWithDate:(NSDate *)date open:(NSNumber *)open close:(NSNumber *)close high:(NSNumber *)high low:(NSNumber *)low;
+ (ChartCandleDataPoint *)chartCandleDataPointWithDate:(NSDate *)date open:(NSNumber *)open close:(NSNumber *)close high:(NSNumber *)high low:(NSNumber *)low;
@end



@interface ChartXYDataPoint : ChartDataPoint
@end
