//
//  JSONValueTransformer+CGSize.h
//  ChartMaker
//
//  Created by Lee Dowthwaite on 27/08/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSONValueTransformer.h"

@interface JSONValueTransformer (CGSize)

- (id)CGSizeFromNSString:(NSString *)string;
- (id)JSONObjectFromCGSize:(CGSize)size;

@end
