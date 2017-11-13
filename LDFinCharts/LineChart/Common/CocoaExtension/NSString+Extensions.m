//
//  NSString+Extensions.m
//  Autobahn-iPad
//
//  Created by Lee Dowthwaite on 04/10/2012.
//  Copyright (c) 2012 Coinnovation Lab. All rights reserved.
//

#import "NSString+Extensions.h"

// helper methods for regex operations on an NSString

@implementation NSString (Extensions)

- (NSString *)stringByReplacingRegexPattern:(NSString *)pattern withSubstitionPattern:(NSString *)subs;
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    return [regex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, [self length]) withTemplate:subs];
}

- (NSUInteger)numberOfMatchesWithRegexPattern:(NSString *)pattern
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    return [regex numberOfMatchesInString:self options:0 range:NSMakeRange(0, [self length])];
}

- (NSArray *)matchesWithRegexPattern:(NSString *)pattern
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    return [regex matchesInString:self options:0 range:NSMakeRange(0, [self length])];
}

- (NSString *)stringByRemovingFunnyCharacters
{
    NSString *result = [self stringByReplacingRegexPattern:@"[\\\\/&%]" withSubstitionPattern:@" "];
    return result;
}


@end
