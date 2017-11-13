//
//  NSBezierPath+TextSupport.h
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 27/02/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

@interface NSBezierPath (TextSupport)

+ (NSBezierPath *)bezierPathFromString:(NSString *)string withFont:(NSFont *)font inRect:(CGRect)rect;

void ApplyCenteredPathTransform(NSBezierPath *path, CGAffineTransform transform);
NSBezierPath *PathByApplyingTransform(NSBezierPath *path, CGAffineTransform transform);
void RotatePath(NSBezierPath *path, CGFloat theta);
void ScalePath(NSBezierPath *path, CGFloat sx, CGFloat sy);
void OffsetPath(NSBezierPath *path, CGSize offset);
void MovePathToPoint(NSBezierPath *path, CGPoint destPoint);
void MovePathCenterToPoint(NSBezierPath *path, CGPoint destPoint);


@end
