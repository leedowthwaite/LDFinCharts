//
//  CMKMacros.h
//  ChartMaker
//
//  Created by Lee Dowthwaite on 29/03/2015.
//  Copyright (c) 2015 Echelon Developments Ltd. All rights reserved.
//

#ifndef ChartMaker_CMKMacros_h
#define ChartMaker_CMKMacros_h

#define JSON_BACKED_SCALAR  nonatomic,assign
#define JSON_BACKED_OBJECT  nonatomic,strong
#define JSON_BACKED         nonatomic

#define THROW_ABSTRACT_INSTANTIATION_EXCEPTION  [NSException raise:@"Attempt to instantiate abstract class" format:@"%@: %@", [self class], NSStringFromSelector(_cmd)]

#endif
