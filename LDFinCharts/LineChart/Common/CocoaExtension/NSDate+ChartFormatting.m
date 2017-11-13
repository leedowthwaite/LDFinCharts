//
//  NSDate+ChartFormatting.m
//
//  Created by Lee Dowthwaite on 25/04/2012.
//  Copyright (c) 2017 Echelon Developments Ltd. All rights reserved.
//

#import "NSDate+ChartFormatting.h"

@implementation NSDate (ChartFormatting)

static const char *kStandardFormatCStr = "%d-%b-%Y %H:%M:%S";
static const char *kReverseFormatCStr = "%Y-%b-%d";
static const char *kISO8601FormatCStr = "%Y-%b-%d'T'%H:%M:%S.SSSZ";  // 2014-01-03T00:00:00.000Z ISO8601
static const char *kDateOnlyFormatCStr = "%d-%b-%Y";
static const char *kDateOnlyMinFormatCStr = "%Y%b%d";
//static const char *kDateOnlyFormatCStr = "%A, %d %B %Y";
static const char *kTimeOnlyFormatCStr = "%H:%M";
static const char *kTimeWithSecFormatCStr = "%H:%M:%S";

// constants for 'time until' calculations. They are rough guides only.
static const NSTimeInterval kTimeIntervalOneDay = (60*60*24);
static const NSTimeInterval kTimeIntervalOneYear = (kTimeIntervalOneDay * 365.25f);  // factor in leap years at this scale
static const NSTimeInterval kTimeIntervalOneMonth = (kTimeIntervalOneYear / 12.0f);  // just use an average month

#pragma mark - component-based date testing and manipulation functions

- (BOOL)isSameDayAs:(NSDate *)date
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:self];
    NSDate *day = [cal dateFromComponents:components];
    components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:date];
    NSDate *otherDay = [cal dateFromComponents:components];
    return ([day isEqualToDate:otherDay]);
}

- (BOOL)isSameMonthAs:(NSDate *)date
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth) fromDate:self];
    NSDate *month = [cal dateFromComponents:components];
    components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth) fromDate:date];
    NSDate *otherMonth = [cal dateFromComponents:components];
    return ([month isEqualToDate:otherMonth]);
}

- (BOOL)isToday
{
    return [self isSameDayAs:[NSDate date]];
}

- (BOOL)isOlderThan24Hours
{
    NSDate *fourthyEightHoursAgo = [NSDate dateWithTimeIntervalSinceNow:-24.0*60.0*60.0];
    return ([self earlierDate:fourthyEightHoursAgo] == self);
}

- (NSDate *)dateByApplyingComponent:(NSCalendarUnit)component value:(NSInteger)value
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    //[cal setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:self];
    [components setValue:value forComponent:component];
    return [cal dateFromComponents:components];
}

- (NSDate *)firstDayOfMonth
{
    return [self dateByApplyingComponent:NSCalendarUnitDay value:1];
}

- (NSDate *)firstDayOfNextMonth
{
//    NSDate *first = [self firstDayOfMonth];
    NSCalendar *cal = [NSCalendar currentCalendar];
//    [cal setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]]; // important to suppress issues when traversing DST boundary
    NSDateComponents *components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:self];
    components.day = 1;
    NSDate *first = [cal dateFromComponents:components];
    NSDateComponents *monthComponents = [[NSDateComponents alloc] init];
    monthComponents.month = 1;
    return [cal dateByAddingComponents:monthComponents toDate:first options:0];
}

- (NSDate *)dateByAddingMonths:(NSInteger)months
{
    NSCalendar *cal = [NSCalendar currentCalendar];
//    [cal setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]]; // important to suppress issues when traversing DST boundary
    NSDateComponents *monthComponents = [[NSDateComponents alloc] init];
    monthComponents.month = months;
    return [cal dateByAddingComponents:monthComponents toDate:self options:0];
}

#pragma mark - Unix format support

+ (NSDate *)dateWithUnixFormat:(NSString *)format timestamp:(NSString *)timestamp
{
    return [self dateWithUnixFormatCStr:(const char *)[format UTF8String] timestamp:timestamp];
}

// Optimized formatter using const format string and C-level formatting functions
+ (NSDate *)dateWithUnixFormatCStr:(const char *)format timestamp:(NSString *)timestamp
{
    if (!timestamp)
    {
        return nil;
    }
    struct tm  tm;
    memset( &tm, 0, sizeof(struct tm));
    strptime([timestamp UTF8String], format, &tm);
    time_t t = mktime( &tm );
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:t];
    return date;
}

+ (NSDate *)dateWithTimestamp:(NSString *)timestamp
{
    return [self dateWithUnixFormatCStr:kStandardFormatCStr timestamp:timestamp];
}

+ (NSDate *)dateWithReverseTimestamp:(NSString *)timestamp
{
    // this works for e.g. "2014-01-03 00:00:00"

    // &&& TODO: only allocate the formatter once!!!

    NSString *dateString = timestamp;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    // Always use this locale when parsing fixed format date strings
    NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale:posix];
    NSDate *date = [formatter dateFromString:dateString];
    return date;
}

+ (NSDate *)dateWithCompactReverseTimestamp:(NSString *)timestamp
{
    // this works for e.g. "2014-01-03 00:00:00"

    static NSDateFormatter *formatter = nil;
    if (!formatter) formatter = [[NSDateFormatter alloc] init];

    NSString *dateString = timestamp;
    [formatter setDateFormat:@"yyyyMMdd"];
    // incoming time is GMT-relative so set the time zone to remove any DST adjustments from result
    // (if we don't do this, resultant time can change by one hour at DST boundaries)
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    // Always use this locale when parsing fixed format date strings
    NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale:posix];
    NSDate *date = [formatter dateFromString:dateString];
    return date;
}


+ (NSDate *)dateWithISO8601FormatTimestamp:(NSString *)timestamp
{
    // this works for ISO8601 (e.g. 2014-01-03T00:00:00.000Z)

    // &&& TODO: only allocate the formatter once!!!

    NSString *dateString = timestamp;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    // Always use this locale when parsing fixed format date strings
    NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale:posix];
    NSDate *date = [formatter dateFromString:dateString];
    return date;
}

+ (NSString *)timestampWithUnixFormat:(NSString *)format date:(NSDate *)date
{
    return [self timestampWithUnixFormatCStr:(const char *)[format UTF8String] date:date];
}


// Optimized formatter using const format string and C-level formatting functions
+ (NSString *)timestampWithUnixFormatCStr:(const char *)format date:(NSDate *)date
{
    struct tm *tm;
    char buffer[80];
    time_t rawtime = [date timeIntervalSince1970]; // - [[NSTimeZone localTimeZone] secondsFromGMT];
    tm = localtime(&rawtime);
//    tm = gmtime(&rawtime);
    strftime(buffer, 80, format, tm);
    return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}



+ (NSString *)timestampWithDate:(NSDate *)date
{
    return [self timestampWithUnixFormatCStr:kStandardFormatCStr date:date];
}

#pragma mark - standard UI formatting methods: use these for all date/time info displayed on the UI

+ (NSDateFormatter *)standardFormatter
{
    static __strong NSDateFormatter *formatter = nil;
    if (!formatter)
    {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
//        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        [formatter setDateFormat:@"dd-MMM-yyyy HH:mm:ss"];

    }
    return formatter;
}

// date from formatted timestamp - always use this method to get an NSDate from a standard internal string-formatted timestamp
+ (NSDate *)dateWithFormattedTimestamp:(NSString *)timestamp
{
    return [self dateWithTimestamp:timestamp];
}

// date from standard formatted date only (no time)
+ (NSDate *)dateWithFormattedDate:(NSString *)dateString
{
    return [self dateWithUnixFormatCStr:kDateOnlyFormatCStr timestamp:dateString];
}

// date from minimum formatted date only (no time) e.g. from <OpenDate>20101124</OpenDate>
+ (NSDate *)dateWithMinFormattedDate:(NSString *)dateString
{
    return [self dateWithUnixFormatCStr:kDateOnlyMinFormatCStr timestamp:dateString];
}

// complete formatted timestamp - always use this method to get a string formatted timestamp from an NSDate
- (NSString *)formattedDateAsTimestamp
{
    return [[self class] timestampWithDate:self];
}

// abbreviated date for UI - if it's today, returns formatted time only, else returns formatted date only
- (NSString *)formattedDateAbbreviated
{
    if ([self isToday])
    {
//        return [[self class] timestampWithUnixFormatCStr:kTimeOnlyFormatCStr date:self];
        return [self formattedDateAsTimeWithSecondsLocal];
    }
    else 
    {
//        return [[self class] timestampWithUnixFormat:@"%d %b" date:self];
        return [self formattedDateAsDateLocal];
    }
}

// time only
- (NSString *)formattedDateAsTime
{
    return [[self class] timestampWithUnixFormatCStr:kTimeOnlyFormatCStr date:self];
}

// Time formated locally as "HH:mm:ss [am|pm]" depending on locale and Date/Time settings.
- (NSString *)formattedDateAsTimeWithSecondsLocal
{
    static __strong NSDateFormatter *formatter = nil;
    if (!formatter)
    {
        formatter = [[NSDateFormatter alloc] init];
        // Using the predefined (and incorrectly-documented) NSDateFormatterMediumStyle does what we need in terms of setting the time to 12/24h and respecting the locale.
        [formatter setTimeStyle:NSDateFormatterMediumStyle];
        [formatter setDateStyle:NSDateFormatterNoStyle];
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    return [formatter stringFromDate:self];
}

// day and date, formatted locally e.g. "Thursday, 03 October 2013"
- (NSString *)formattedDateAsDayAndDateLocal
{
    static __strong NSDateFormatter *formatter = nil;
    if (!formatter)
    {
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"EEEEddMMMMYYYY" options:0 locale:[NSLocale currentLocale]];
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:formatString];
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
//        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    }
    return [formatter stringFromDate:self];
}

// day and date, formatted locally e.g. "Thur, 03 Oct 2013"
- (NSString *)formattedDateAsDayAndDateLocalShort
{
    static __strong NSDateFormatter *formatter = nil;
    if (!formatter)
    {
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"EEddMMMYYYY" options:0 locale:[NSLocale currentLocale]];
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:formatString];
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
        //        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    }
    return [formatter stringFromDate:self];
}

// date, formatted locally e.g. "03 Oct 2013"
- (NSString *)formattedDateAsDateLocalMedium
{
    static __strong NSDateFormatter *formatter = nil;
    if (!formatter)
    {
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"ddMMMYYYY" options:0 locale:[NSLocale currentLocale]];
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:formatString];
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    return [formatter stringFromDate:self];
}

// date, formatted short locally e.g. "03/10/2013" (UK)
- (NSString *)formattedDateAsDateLocalShort
{
    static __strong NSDateFormatter *formatter = nil;
    if (!formatter)
    {
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"ddMMYYYY" options:0 locale:[NSLocale currentLocale]];
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:formatString];
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
        //        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    }
    return [formatter stringFromDate:self];
}

// date only, formatted locally e.g. "03 October 2013"
- (NSString *)formattedDateAsDateLocal
{
    static __strong NSDateFormatter *formatter = nil;
    if (!formatter)
    {
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"ddMMMMYYYY" options:0 locale:[NSLocale currentLocale]];
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:formatString];
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
//        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    }
    return [formatter stringFromDate:self];
}

// day, date and time, formatted locally e.g. "Tuesday 29 October 16:36:39"
- (NSString *)formattedDateAsDayDateAndTimeLocal
{
    static __strong NSDateFormatter *formatter = nil;
    if (!formatter)
    {
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"EEEEddMMMMHHmmss" options:0 locale:[NSLocale currentLocale]];
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:formatString];
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    return [formatter stringFromDate:self];
}

// 24-hour time, formatted independently of locale, e.g. "16:36:39"
// Do NOT attempt to use an NSDateFormatter for this - it will not work in come instances.
- (NSString *)formattedDateAs24HourTimeWithSec
{
    return [[self class] timestampWithUnixFormatCStr:kTimeWithSecFormatCStr date:self];
}

// ISO8601 format
- (NSString *)formattedDateAsISO8601
{
    return [[self class] timestampWithUnixFormatCStr:kISO8601FormatCStr date:self];
}

// date only, formatted as standard string
- (NSString *)formattedDateAsDate
{
    return [[self class] timestampWithUnixFormatCStr:kDateOnlyFormatCStr date:self];
}

- (NSString *)formattedTimezoneAsOffset
{
    return [[self class] timestampWithUnixFormat:@"%z" date:self];
}

- (NSString *)yearsMonthsAndDaysUntil
{
    NSTimeInterval interval = [self timeIntervalSinceDate:[NSDate date]];
    if (interval >= 0)
    {
        float years = interval / kTimeIntervalOneYear;
        if (years >= 1.0f)
        {
            float months = fmod(interval, kTimeIntervalOneYear) / kTimeIntervalOneMonth;
            return [NSString stringWithFormat:@"%dY%dM", (int)years, (int)months];
        }
        else
        {
            float months = interval / kTimeIntervalOneMonth;
            if (months >= 1.0f)
            {
                return [NSString stringWithFormat:@"%dM", (int)months];
            }
            else
            {
                float days = interval / kTimeIntervalOneDay;
                return [NSString stringWithFormat:@"%dD", (int)days];
            }
        }
    }
    else
    {
        // target date is in past
        return @"Matured";
    }
}

#pragma mark - misc conversion functions

+ (NSDate *)dateWithWebServiceString:(NSString *)dateString
{
    return [[[self class] standardFormatter] dateFromString:dateString];
}

+ (NSDateFormatter *)JSONDateFormatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
//    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    return dateFormatter;
}

+ (NSString *)JSONStringWithDate:(NSDate *)date
{
    assert(0);  // no longer needed and may cause confusion with date formats
    return [[[self class] JSONDateFormatter] stringFromDate:date];
}

+ (NSDate *)dateWithJSONString:(NSString *)dateString
{
    assert(0);  // no longer needed and may cause confusion with date formats
    return [[[self class] JSONDateFormatter] dateFromString:dateString];
}

- (NSString *)toJSONString
{
    assert(0);  // no longer needed and may cause confusion with date formats
    return [[self class] JSONStringWithDate:self];
}


#pragma mark - Search API conversions

// NOTE: the webservices all use epoch values expressed as milliseconds rather than seconds.

+ (NSDate *)dateWithEpochTime:(NSString *)epochString
{
    NSTimeInterval epochSeconds = [epochString doubleValue]/1000;
    NSDate *epochDate = [[NSDate alloc] initWithTimeIntervalSince1970:epochSeconds];
    return epochDate;
}

+ (NSDate *)dateWithEpochLongLong:(long long)epochLongLong
{
    NSTimeInterval epochSeconds = (float)epochLongLong/1000.0f;
    NSDate *epochDate = [[NSDate alloc] initWithTimeIntervalSince1970:epochSeconds];
    return epochDate;
}

// epoch in milliseconds as a 64-bit value
- (long long)toEpochLongLong
{
    NSTimeInterval interval = [self timeIntervalSince1970];
    return (long long)(interval * 1000.0f);
}

- (NSString *)toEpochString
{
    return [NSString stringWithFormat:@"%lld", [self toEpochLongLong]];
}

#pragma mark - workarounds for relative search service 'timestamps'

+ (NSTimeInterval)timeAgoForString:(NSString *)string
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d+) (minutes|hours|days) ago" options:NSRegularExpressionCaseInsensitive error:&error];
    assert(!error);
    NSTextCheckingResult *match = [regex firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
    if (match)
    {
        NSRange numberRange = [match rangeAtIndex:1];
        NSRange unitRange = [match rangeAtIndex:2];
        NSString *number = [string substringWithRange:numberRange];
        NSString *units = [string substringWithRange:unitRange];
        int num = [number intValue];
        int multiplier = 0;
        if ([units isEqualToString:@"minutes"])
        {
            multiplier = 60;
        }
        else if ([units isEqualToString:@"hours"])
        {
            multiplier = 60*60;
        }
        else if ([units isEqualToString:@"days"])
        {
            multiplier = 60*60*24;
        }
        return (NSTimeInterval)(multiplier * num);
    }
    return 0;
}

+ (NSDate *)dateForString:(NSString *)string
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d+)-(\\w+)-(\\d+)" options:NSRegularExpressionCaseInsensitive error:&error];
    assert(!error);
    NSTextCheckingResult *match = [regex firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
    if (match)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
//        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        [dateFormatter setDateFormat:@"dd-MMM-yyyy"];
        NSDate *date = [dateFormatter dateFromString:string];
        assert(date);
        return date;
    }
    return nil;
}

+ (NSString *)convertTimestampString:(NSString *)string
{
    NSDate *now = [NSDate date];
    NSDate *date = nil;

    if ([string isEqualToString:@"Yesterday"])
    {
        date = [now dateByAddingTimeInterval:-86400.0f];
    }
    
    NSTimeInterval t = [[self class] timeAgoForString:string];
    if (t > 0.1f)
    {
        date = [now dateByAddingTimeInterval:-t];
    }
    else 
    {
        NSDate *absoluteDate = [[self class] dateForString:string];
        if (absoluteDate)
        {
            date = absoluteDate;
        }
    }


    if (date)
    {
        NSString *formatted = [date formattedDateAsTimestamp];
        
        return formatted;
    }
    else 
    {
        NSLog( @"WARNING: unexpected timestamp format: %@", string );
    }
    return string;
}




@end
