//
//  NSBezierPath+TextSupport.m
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 27/02/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "NSBezierPath+BezierPathQuartzUtilities.h"
#import "NSBezierPath+TextSupport.h"
#import "NSBezierPath+MCAdditions.h"

@implementation NSBezierPath (TextSupport)

#pragma mark - General Geometry
CGPoint RectGetCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

#pragma mark - Bounds

CGRect PathBoundingBox(NSBezierPath *path)
{
    return CGPathGetPathBoundingBox([path quartzPath]);
}

CGRect PathBoundingBoxWithLineWidth(NSBezierPath *path)
{
    CGRect bounds = PathBoundingBox(path);
    return CGRectInset(bounds, -path.lineWidth / 2.0f, -path.lineWidth / 2.0f);
}

CGPoint PathBoundingCenter(NSBezierPath *path)
{
    return RectGetCenter(PathBoundingBox(path));
}

CGPoint PathCenter(NSBezierPath *path)
{
    return RectGetCenter(path.bounds);
}


#pragma mark - Transform
/*
void ApplyCenteredPathTransform(NSBezierPath *path, CGAffineTransform transform)
{
    CGPoint center = PathBoundingCenter(path);
    CGAffineTransform t = CGAffineTransformIdentity;
    t = CGAffineTransformTranslate(t, center.x, center.y);
    t = CGAffineTransformConcat(transform, t);
    t = CGAffineTransformTranslate(t, -center.x, -center.y);
    [path applyTransform:t];
}
*/

NSBezierPath *PathByApplyingTransform(NSBezierPath *path, CGAffineTransform transform)
{
    NSBezierPath *copy = [path copy];
    ApplyCenteredPathTransform(copy, transform);
    return copy;
}

void RotatePath(NSBezierPath *path, CGFloat theta)
{
    CGAffineTransform t = CGAffineTransformMakeRotation(theta);
    ApplyCenteredPathTransform(path, t);
}

void ScalePath(NSBezierPath *path, CGFloat sx, CGFloat sy)
{
    CGAffineTransform t = CGAffineTransformMakeScale(sx, sy);
    ApplyCenteredPathTransform(path, t);
}

void OffsetPath(NSBezierPath *path, CGSize offset)
{
    CGAffineTransform t = CGAffineTransformMakeTranslation(offset.width, offset.height);
    ApplyCenteredPathTransform(path, t);
}

void MovePathToPoint(NSBezierPath *path, CGPoint destPoint)
{
    CGRect bounds = PathBoundingBox(path);
    CGPoint p1 = bounds.origin;
    CGPoint p2 = destPoint;
    CGSize vector = CGSizeMake(p2.x - p1.x, p2.y - p1.y);
    OffsetPath(path, vector);
}

void MovePathCenterToPoint(NSBezierPath *path, CGPoint destPoint)
{
    CGRect bounds = PathBoundingBox(path);
    CGPoint p1 = bounds.origin;
    CGPoint p2 = destPoint;
    CGSize vector = CGSizeMake(p2.x - p1.x, p2.y - p1.y);
    vector.width -= bounds.size.width / 2.0f;
    vector.height -= bounds.size.height / 2.0f;
    OffsetPath(path, vector);
}

void MirrorPathHorizontally(NSBezierPath *path)
{
    CGAffineTransform t = CGAffineTransformMakeScale(-1, 1);
    ApplyCenteredPathTransform(path, t);
}

void MirrorPathVertically(NSBezierPath *path)
{
    CGAffineTransform t = CGAffineTransformMakeScale(1, -1);
    ApplyCenteredPathTransform(path, t);
}
/*
void FitPathToRect(NSBezierPath *path, CGRect destRect)
{
    CGRect bounds = PathBoundingBox(path);
    CGRect fitRect = RectByFittingRect(bounds, destRect);
    CGFloat scale = AspectScaleFit(bounds.size, destRect);
    
    CGPoint newCenter = RectGetCenter(fitRect);
    MovePathCenterToPoint(path, newCenter);
    ScalePath(path, scale, scale);
}
*/
// Courtesy of Erica Sadun
//
//NSBezierPath *BezierPathFromString(NSString *string, NSFont *font)
//
+ (NSBezierPath *)bezierPathFromString:(NSString *)string withFont:(NSFont *)font inRect:(CGRect)rect
{
    // Initialize path
    NSBezierPath *path = [NSBezierPath bezierPath];
    if (!string.length) return path;
    
    // Create font ref
    CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    if (fontRef == NULL)
    {
        NSLog(@"Error retrieving CTFontRef from NSFont");
        return nil;
    }
    
    // Create glyphs
    CGGlyph *glyphs = malloc(sizeof(CGGlyph) * string.length);
    const unichar *chars = (const unichar *)[string cStringUsingEncoding:NSUnicodeStringEncoding];
    BOOL success = CTFontGetGlyphsForCharacters(fontRef, chars,  glyphs, string.length);
    if (!success)
    {
        NSLog(@"Error retrieving string glyphs");
        CFRelease(fontRef);
        free(glyphs);
        return nil;
    }

    // Draw each char into path
    for (int i = 0; i < string.length; i++)
    {
        if ([string characterAtIndex:i] != ' ')
        {
            CGGlyph glyph = glyphs[i];
            CGPathRef pathRef = CTFontCreatePathForGlyph(fontRef, glyph, NULL);
            [path appendBezierPath:[NSBezierPath bezierPathWithCGPath:pathRef]];
            CGPathRelease(pathRef);
            CGSize size = [[string substringWithRange:NSMakeRange(i, 1)] sizeWithAttributes:@{NSFontAttributeName:font}];
            OffsetPath(path, CGSizeMake(-size.width, 0));
        }
    }
    
    // Clean up
    free(glyphs);
    CFRelease(fontRef);
    
    // Math
    MirrorPathVertically(path);
//    FitPathToRect(rect);

    MovePathToPoint(path, rect.origin);
    
    return path;
}

@end
