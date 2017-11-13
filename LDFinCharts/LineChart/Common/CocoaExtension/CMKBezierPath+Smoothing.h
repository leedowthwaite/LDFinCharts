//
//  CMKBezierPath+Smoothing.h
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 24/02/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

//#import <UIKit/UIKit.h>
#import "CMKType.h"

@interface CMKBezierPath (Smoothing)

- (CMKBezierPath *)smoothedPathWithGranularity:(NSInteger)granularity;
+ (CMKBezierPath *)quadCurvedPathWithPoints:(NSArray *)points;

@end
