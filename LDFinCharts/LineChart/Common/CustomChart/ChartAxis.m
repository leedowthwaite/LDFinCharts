//
//  ChartAxis.m
//  CryptoIMD
//
//  Created by Lee Dowthwaite on 03/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKMacros.h"
#import "ChartAxis.h"
#import "NSDate+ChartFormatting.h"
#import "CMKBezierPath+CMKExtensions.h"
#import "ChartSeries.h"
#import "CMKColor+CMKExtensions.h"
#import "CALayer+Extensions.h"

@implementation ChartAxis

- (id)init
{
    self = [super init];
    if (self)
    {
        self.autoGridlines = YES;
        self.labelsVisible = YES;
    }
    return self;
}

- (void)addSeries:(ChartSeries *)series
{
    // on x-axis, don't add any derived series since they should use the source time series and any gap processing it has undergone
    if (!series.derivedFrom)
    {
        if (self.series)
        {
            [self.series addSeries:series];
        }
        else
        {
            self.series = [[ChartSeries alloc] init];
            [self.series addSeries:series];
        }
    }
}

- (void)setSeries:(ChartSeries *)series
{
    _series = series;
    // invoke x/y-specific subclass methods to create the paths
//    self.axisBezierPath = [self bezierPathForAxisForSeries:series];
//    self.gridlinesBezierPath = [self bezierPathForAxisGridlinesForSeries:series];
//    self.labelsBezierPath = [self bezierPathForAxisLabelsForSeries:series];
}

#pragma mark - getters

- (CMKBezierPath *)axisBezierPath
{
    return (self.model.hidden ? nil : (self.model.lineStyle.hidden ? nil : [self bezierPathForAxisForSeries:self.series]));
}

- (CMKBezierPath *)tickmarksBezierPath
{
    return (self.model.axisTickMarks ? nil : [self bezierPathForAxisTickmarksForSeries:self.series]);
}

- (CMKBezierPath *)gridlinesBezierPath
{
    return (self.model.gridlinesStyle.hidden ? nil : [self bezierPathForAxisGridlinesForSeries:self.series major:NO]);
}

- (CMKBezierPath *)majorGridlinesBezierPath
{
    return (self.model.gridlinesStyle.hidden ? nil : [self bezierPathForAxisGridlinesForSeries:self.series major:YES]);
}


- (CMKBezierPath *)labelsBezierPath
{
    return (self.model.labelsStyle.hidden ? nil : [self bezierPathForAxisLabelsForSeries:self.series]);
}

#pragma mark - abstract interface

// factory - must override
+ (ChartAxis *)axisWithJSONDict:(NSDictionary *)json
{
    THROW_ABSTRACT_INSTANTIATION_EXCEPTION;
    return nil;
}

// factory - must override
+ (ChartAxis *)axisWithModel:(ChartAxisModel *)model
{
    THROW_ABSTRACT_INSTANTIATION_EXCEPTION;
    return nil;
}

// designated initializer
- (id)initWithModel:(ChartAxisModel *)model
{
    self = [super init];
    if (self)
    {
        [self configureFromModel:model];
    }
    return self;
}

- (void)configureFromModel:(ChartAxisModel *)model
{
    self.model = model;
}


// must override
- (CMKBezierPath *)bezierPathForAxisForSeries:(ChartSeries *)series
{
    THROW_ABSTRACT_INSTANTIATION_EXCEPTION;
    return nil;
}

// must override
//- (CMKBezierPath *)bezierPathForAxisGridlinesForSeries:(ChartSeries *)series
//{
//    THROW_ABSTRACT_INSTANTIATION_EXCEPTION;
//    return nil;
//}

// must override
- (CMKBezierPath *)bezierPathForAxisGridlinesForSeries:(ChartSeries *)series major:(BOOL)major
{
    THROW_ABSTRACT_INSTANTIATION_EXCEPTION;
    return nil;
}

// must override
- (CMKBezierPath *)bezierPathForAxisTickmarksForSeries:(ChartSeries *)series
{
    THROW_ABSTRACT_INSTANTIATION_EXCEPTION;
    return nil;
}

// must override
- (CMKBezierPath *)tickmarksBezierPathForModel:(CMKTickMarksModel *)model
{
    THROW_ABSTRACT_INSTANTIATION_EXCEPTION;
    return nil;
}


- (CMKBezierPath *)bezierPathForAxisLabelsForSeries:(ChartSeries *)series
{
    THROW_ABSTRACT_INSTANTIATION_EXCEPTION;
    return nil;
}

#pragma mark -

- (CMKBezierPath *)pathForXAxis
{
    CGRect rect = [self.delegate axisViewBounds];
    BZPATH *path = [BZPATH bezierPath];
    BZPATH_MOVE_TO(path,CGPointMake(rect.origin.x,self.viewRangeY/*-self.labelMargin*/-1));
    BZPATH_LINE_TO(path,CGPointMake(self.viewRangeX,self.viewRangeY/*-self.labelMargin*/-1));
    return path;
}

- (CMKBezierPath *)pathForYAxis
{
    CGRect rect = [self.delegate axisViewBounds];
    BZPATH *path = [BZPATH bezierPath];
    // normal left hand Y axis
    BZPATH_MOVE_TO(path,CGPointMake(rect.origin.x/*-self.labelMargin*/,self.viewRangeY-1));
    BZPATH_LINE_TO(path,CGPointMake(rect.origin.x/*-self.labelMargin*/,rect.origin.y));
    // right-hand y axis
//    BZPATH_MOVE_TO(path,CGPointMake(self.viewRangeX-self.labelMargin,self.viewRangeY-1));
//    BZPATH_LINE_TO(path,CGPointMake(self.viewRangeX-self.labelMargin,rect.origin.y));
    return path;
}

#pragma mark - mapping helpers

- (CGPoint)mapPoint:(CGPoint)dp toViewRect:(CGRect)viewRect
{
    if (self.zoomWindow)
    {
        return [self.series mapPoint:dp toViewRect:viewRect zoomWindow:*self.zoomWindow];
    }
    else
    {
        return [self.series mapPoint:dp toViewRect:viewRect];
    }
}


#pragma mark - shape generation

- (CAShapeLayer *)shapeForAxisInViewRect:(CGRect)viewRect
{
    CMKColor *strokeColor = [CMKColor colorWithARGB:(int)self.model.lineStyle.lineColor.colorValue];

    // shape can be used for line without rest of path closure
    CAShapeLayer *shape = [[CAShapeLayer alloc] init];
    shape.frame = viewRect;
    shape.path = self.axisBezierPath.CGPath;
    shape.strokeColor = strokeColor.CGColor;
    shape.lineWidth = self.model.lineStyle.lineWidth;
    shape.fillColor = nil;
    shape.lineCap = [self.model.lineStyle lineEndCapStyleAsCAString];
    shape.lineJoin = [self.model.lineStyle lineJoinStyleAsCAString];
    [ChartSeries setDashPatternOnShape:shape forStyle:self.model.lineStyle];

    if (!self.model.gridlinesStyle.hidden)
    {
        CMKColor *gridlinesColor = [CMKColor colorWithARGB:(int)self.model.gridlinesStyle.lineColor.colorValue];
        CAShapeLayer *gridlinesShape = [[CAShapeLayer alloc] init];
        [gridlinesShape setName:@"gridlines"];
        gridlinesShape.frame = viewRect;
        gridlinesShape.path = self.gridlinesBezierPath.CGPath;
        gridlinesShape.strokeColor = gridlinesColor.CGColor;
        gridlinesShape.lineWidth = self.model.gridlinesStyle.lineWidth;
        gridlinesShape.fillColor = nil;
        gridlinesShape.lineCap = [self.model.gridlinesStyle lineEndCapStyleAsCAString];
        gridlinesShape.lineJoin = [self.model.gridlinesStyle lineJoinStyleAsCAString];
        [ChartSeries setDashPatternOnShape:gridlinesShape forStyle:self.model.gridlinesStyle];
        [shape addSublayer:gridlinesShape];

        if (!self.model.majorGridlinesStyle.hidden)
        {
            CMKBezierPath *majorPath = self.majorGridlinesBezierPath;
            if (majorPath)
            {
                CMKColor *majorGridlinesColor = [CMKColor colorWithARGB:(int)self.model.majorGridlinesStyle.lineColor.colorValue];
                CAShapeLayer *gridlinesShape = [[CAShapeLayer alloc] init];
                [gridlinesShape setName:@"gridlines-major"];
                gridlinesShape.frame = viewRect;
                gridlinesShape.path = majorPath.CGPath;
                gridlinesShape.strokeColor = majorGridlinesColor.CGColor;
                gridlinesShape.lineWidth = self.model.majorGridlinesStyle.lineWidth;
                gridlinesShape.fillColor = nil;
                gridlinesShape.lineCap = [self.model.majorGridlinesStyle lineEndCapStyleAsCAString];
                gridlinesShape.lineJoin = [self.model.majorGridlinesStyle lineJoinStyleAsCAString];
                [ChartSeries setDashPatternOnShape:gridlinesShape forStyle:self.model.majorGridlinesStyle];
                [shape addSublayer:gridlinesShape];
            }
        }
        
    }

    if (self.model.axisTickMarks)
    {
        // look at what tickmark models are present
        for (CMKTickMarksModel *model in self.model.axisTickMarks)
        {
            CMKColor *tickMarksColor = [CMKColor colorWithARGB:(int)model.lineStyle.lineColor.colorValue];
            CAShapeLayer *tickMarksShape = [[CAShapeLayer alloc] init];
            NSString *tag = [NSString stringWithFormat:@"tickmarks-%@", (model.tag ? model.tag : @"")];
            [tickMarksShape setName:tag];
            tickMarksShape.frame = viewRect;
            tickMarksShape.path = [self tickmarksBezierPathForModel:model].CGPath;
            tickMarksShape.lineWidth = model.lineStyle.lineWidth;
            tickMarksShape.strokeColor = tickMarksColor.CGColor;
            if (model.customPath.fillColor)
            {
                tickMarksShape.fillColor = [UIColor colorWithARGB:model.customPath.fillColor.colorValue].CGColor;
            }
            else
            {
                tickMarksShape.fillColor = (model.style == CMKTickMarkStyleDot ? tickMarksShape.strokeColor : nil);
            }
            tickMarksShape.lineCap = [model.lineStyle lineEndCapStyleAsCAString];
            tickMarksShape.lineJoin = [model.lineStyle lineJoinStyleAsCAString];
            [ChartSeries setDashPatternOnShape:tickMarksShape forStyle:model.lineStyle];
            [shape addSublayer:tickMarksShape];
        }
    }

    // add the labels
    CMKColor *labelColor = [CMKColor colorWithARGB:(int)self.model.labelsStyle.colorValue];
    CAShapeLayer *labelsShape = [[CAShapeLayer alloc] init];
    [labelsShape setName:@"labels"];
    labelsShape.frame = viewRect;
    labelsShape.path = self.labelsBezierPath.CGPath;
    labelsShape.strokeColor = labelColor.CGColor;
    labelsShape.lineWidth = self.model.labelsStyle.lineWidth;
    labelsShape.fillColor = labelColor.CGColor;
    [shape addSublayer:labelsShape];


    return shape;
}

// Update paths in the axis shape and all its subshapes
- (CAShapeLayer *)updatePathsForAxisShape:(CAShapeLayer *)shape
{
    // main shape
    shape.path = self.axisBezierPath.CGPath;
    if (!self.model.gridlinesStyle.hidden)
    {
        // gridlines
        CAShapeLayer *gridlinesShape = (CAShapeLayer *)[shape sublayerNamed:@"gridlines"];
        gridlinesShape.path = self.gridlinesBezierPath.CGPath;

        CMKBezierPath *majorPath = self.majorGridlinesBezierPath;
        if (majorPath)
        {
            CAShapeLayer *gridlinesShape = (CAShapeLayer *)[shape sublayerNamed:@"gridlines-major"];
            gridlinesShape.path = majorPath.CGPath;
        }
    }
    if (self.model.axisTickMarks)
    {
        // tickmarks
        // look at what tickmark models are present
        for (CMKTickMarksModel *model in self.model.axisTickMarks)
        {
            NSString *tag = [NSString stringWithFormat:@"tickmarks-%@", (model.tag ? model.tag : @"")];
            CAShapeLayer *tickmarksShape = (CAShapeLayer *)[shape sublayerNamed:tag];
            tickmarksShape.path = [self tickmarksBezierPathForModel:model].CGPath;
        }
    }
    // labels
    CAShapeLayer *labelsShape = (CAShapeLayer *)[shape sublayerNamed:@"labels"];
    labelsShape.path = self.labelsBezierPath.CGPath;

    return shape;
}



#pragma mark - getters

- (CGFloat)viewRangeX
{
    CGRect rect = [self.delegate axisViewBounds];
    return rect.origin.x+rect.size.width;
}

- (CGFloat)viewRangeY
{
    CGRect rect = [self.delegate axisViewBounds];
    return rect.origin.y+rect.size.height;
}

- (CGFloat)padding
{
    return self.model.padding;
}

- (CGFloat)labelMargin
{
    return self.model.labelMargin;
}

#pragma mark - line pattern methods

- (void)setLinePatternOnPath:(CMKBezierPath *)path forStyle:(CMKLineStyleModel *)style
{
    if (style.dashPattern)
    {
        NSArray *pattern = [style dashPatternAsArray];
        if (pattern && [pattern count] > 0)
        {
            [path setDashPatternFromArray:pattern];
        }
    }
    else
    {
        switch (style.simpleLineStyle)
        {
            case CMKLineStyleDashed:
            {
                CGFloat dashes[] = {5,5};
                [path setLineDash:dashes count:2 phase:0];
                break;
            }
            case CMKLineStyleDotted:
            {
                CGFloat dashes[] = {2,2};
                [path setLineDash:dashes count:2 phase:0];
                break;
            }

            case CMKLineStyleSolid:
            case CMKLineStyleNone:
            default:
                break;
        }
    }
}


- (void)setLinePatternOnShape:(CMKBezierPath *)path forStyle:(CMKLineStyleModel *)style
{
    if (style.dashPattern)
    {
        NSArray *pattern = [style dashPatternAsArray];
        if (pattern && [pattern count] > 0)
        {
            [path setDashPatternFromArray:pattern];
        }
    }
    else
    {
        switch (style.simpleLineStyle)
        {
            case CMKLineStyleDashed:
            {
                CGFloat dashes[] = {5,5};
                [path setLineDash:dashes count:2 phase:0];
                break;
            }
            case CMKLineStyleDotted:
            {
                CGFloat dashes[] = {2,2};
                [path setLineDash:dashes count:2 phase:0];
                break;
            }

            case CMKLineStyleSolid:
            case CMKLineStyleNone:
            default:
                break;
        }
    }
}

#pragma mark - label formatting helpers

- (NSString *)formattedStringWithFloat:(CGFloat)val
{
    NSString *abbrevString = [[self class] abbreviatedStringForRawValue:val];
    if (abbrevString)
    {
        return abbrevString;
    }
    else
    {
        return [NSString stringWithFormat:self.model.labelsFormat, val];
    }
}

- (NSString *)formattedStringWithNumber:(NSNumber *)val
{
    return [NSString stringWithFormat:self.model.labelsFormat, [val floatValue]];
}

+ (int)scientificExponentForRawValue:(CGFloat)value
{
    int exponent = (int)floor(log10f(value));
    if (exponent < 5)
    {
        // don't abbreviate numbers below 10,000
        return 0;
    }
    else
    {
        return (exponent/3)*3;
    }
}

+ (NSString *)abbreviatedStringForRawValue:(CGFloat)value
{
    int sciExp = [self scientificExponentForRawValue:value];
    CGFloat div = powf(10, sciExp);
    switch (sciExp) {
        case 3: return [NSString stringWithFormat:@"%0.3fK", value/div];
        case 6: return [NSString stringWithFormat:@"%0.3fM", value/div];
        case 9: return [NSString stringWithFormat:@"%0.3fB", value/div];
        case 12: return [NSString stringWithFormat:@"%0.3fT", value/div];
        default: return nil;
    }
}



@end
