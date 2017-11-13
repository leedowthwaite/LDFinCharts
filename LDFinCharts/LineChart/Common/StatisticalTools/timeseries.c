//
//  timeseries.c
//  ChartMaker
//
//  Created by Lee Dowthwaite on 26/08/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#include "timeseries.h"

float calculateEMA(float currentValue, float period, float lastEMA)
{
    float k = 2 / (period + 1);
    return currentValue * k + lastEMA * (1 - k);
}
