//
//  CMKChartConfigurationController.m
//  ChartMaker
//
//  Created by Lee Dowthwaite on 29/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#import "CMKChartConfigurationController.h"
#import "Chart.h"
#import "ChartView.h"
#import "CMKSerializableModel.h"
#import "ChartModel.h"

@implementation CMKChartConfigurationController

+ (ChartModel *)loadModelFromResourceFile:(NSString *)filename
{
    NSError *error = nil;
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    NSString *jsonString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (error)
    {
        NSLog(@"Error reading from file path %@\nError message: %@", path, [error localizedDescription]);
        assert(!error);
    }
    ChartModel *model = (ChartModel *)[ChartModel modelWithJSONString:jsonString];
    //NSLog(@"model %@", model);
    return model;
}

- (void)configureChartView:(ChartView *)chartView fromFilePath:(NSString *)path
{
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!error)
    {
        [self configureChartView:chartView fromJSON:json];
    }
    else
    {
        NSLog(@"");
    }
}


- (void)configureChartView:(ChartView *)chartView fromJSON:(NSDictionary *)json
{
    NSDictionary *chartModel = json[@"chart"];
    if (chartModel)
    {
        NSDictionary *xAxisModel = chartModel[@"x-axis"];
        if (xAxisModel)
        {
            ChartXAxis *xAxis = [ChartXAxis axisWithJSONDict:xAxisModel];
        }
        // TODO: deal with multiple y axes
        NSDictionary *yAxisModel = chartModel[@"y-axis"];
        if (yAxisModel)
        {
            ChartYAxis *yAxis = [ChartYAxis axisWithJSONDict:yAxisModel];
        }
    
    }

}


@end
