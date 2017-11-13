//
//  NSDate+ChartFormatting.h
//
//  Created by Lee Dowthwaite on 25/04/2012.
//  Copyright (c) 2017 Echelon Developments Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (ChartFormatting)

- (BOOL)isSameDayAs:(NSDate *)date;
- (BOOL)isSameMonthAs:(NSDate *)date;
- (BOOL)isToday;
- (BOOL)isOlderThan24Hours;
- (NSDate *)dateByApplyingComponent:(NSCalendarUnit)component value:(NSInteger)value;
- (NSDate *)firstDayOfMonth;
- (NSDate *)firstDayOfNextMonth;
- (NSDate *)dateByAddingMonths:(NSInteger)months;

+ (NSDateFormatter *)standardFormatter;
+ (NSDate *)dateWithFormattedTimestamp:(NSString *)timestamp;
+ (NSDate *)dateWithFormattedDate:(NSString *)dateString;
+ (NSDate *)dateWithMinFormattedDate:(NSString *)dateString;
+ (NSDate *)dateWithTimestamp:(NSString *)timestamp;
+ (NSDate *)dateWithReverseTimestamp:(NSString *)timestamp;
+ (NSDate *)dateWithCompactReverseTimestamp:(NSString *)timestamp;
+ (NSDate *)dateWithISO8601FormatTimestamp:(NSString *)timestamp;

- (NSString *)formattedDateAsISO8601;
- (NSString *)formattedDateAsTimestamp;
- (NSString *)formattedDateAbbreviated;
- (NSString *)formattedDateAsTime;
- (NSString *)formattedDateAsTimeWithSecondsLocal;
- (NSString *)formattedDateAsDayAndDateLocal;
- (NSString *)formattedDateAsDateLocal;
- (NSString *)formattedDateAsDayAndDateLocalShort;
- (NSString *)formattedDateAsDateLocalMedium;
- (NSString *)formattedDateAsDateLocalShort;
- (NSString *)formattedDateAsDayDateAndTimeLocal;
- (NSString *)formattedDateAs24HourTimeWithSec;
- (NSString *)formattedDateAsDate;
- (NSString *)formattedTimezoneAsOffset;
- (NSString *)yearsMonthsAndDaysUntil;

+ (NSDate *)dateWithWebServiceString:(NSString *)dateString;
//- (NSString *)stringFormattedForReaderPubDate;

+ (NSDateFormatter *)JSONDateFormatter;
+ (NSString *)JSONStringWithDate:(NSDate *)date;
+ (NSDate *)dateWithJSONString:(NSString *)dateString;
- (NSString *)toJSONString;
+ (NSString *)convertTimestampString:(NSString *)string;

+ (NSDate *)dateWithEpochTime:(NSString *)epochString;
+ (NSDate *)dateWithEpochLongLong:(long long)epochLongLong;
- (long long)toEpochLongLong;
- (NSString *)toEpochString;

@end
