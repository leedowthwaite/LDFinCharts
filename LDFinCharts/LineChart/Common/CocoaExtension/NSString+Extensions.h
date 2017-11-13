//
//  NSString+Extensions.h
//  Autobahn-iPad
//
//  Created by Lee Dowthwaite on 04/10/2012.
//  Copyright (c) 2012 Coinnovation Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extensions)

- (NSString *)stringByReplacingRegexPattern:(NSString *)pattern withSubstitionPattern:(NSString *)subs;
- (NSUInteger)numberOfMatchesWithRegexPattern:(NSString *)pattern;
- (NSArray *)matchesWithRegexPattern:(NSString *)pattern;
- (NSString *)stringByRemovingFunnyCharacters;

@end
