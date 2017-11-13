//
//  UIBezierPath+TextSupport.h
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 27/02/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (TextSupport)

+ (UIBezierPath *)bezierPathFromString:(NSString *)string withFont:(UIFont *)font inRect:(CGRect)rect;

void ApplyCenteredPathTransform(UIBezierPath *path, CGAffineTransform transform);
UIBezierPath *PathByApplyingTransform(UIBezierPath *path, CGAffineTransform transform);
void RotatePath(UIBezierPath *path, CGFloat theta);
void ScalePath(UIBezierPath *path, CGFloat sx, CGFloat sy);
void OffsetPath(UIBezierPath *path, CGSize offset);
void MovePathToPoint(UIBezierPath *path, CGPoint destPoint);
void MovePathCenterToPoint(UIBezierPath *path, CGPoint destPoint);


@end
