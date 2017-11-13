//
//  CMKAxisGridlineDescriptor.h
//  stockvibe
//
//  Created by Lee Dowthwaite on 19/02/2016.
//  Copyright © 2016 Echelon Developments Ltd. All rights reserved.
//

#import "CMKType.h"

@interface CMKAxisGridlineDescriptor : NSObject

@property (nonatomic, assign) BOOL major;
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) CGPoint gridlineViewPointStart;
@property (nonatomic, assign) CGPoint gridlineViewPointEnd;
@property (nonatomic, assign) NSTimeInterval epochTime;
@property (nonatomic, strong) NSString *labelText;
@property (nonatomic, assign) CGRect labelBounds;
@property (nonatomic, strong) CMKAxisGridlineDescriptor *prev;
@property (nonatomic, strong) CMKAxisGridlineDescriptor *next;



@end
