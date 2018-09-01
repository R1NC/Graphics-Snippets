//
//  MatrixUtil.h
//  SpriteSDK
//
//  Created by Rinc Liu on 1/9/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Simd/Simd.h>

@interface MatrixUtil : NSObject

+(matrix_float4x4)makeIdentity;

+(matrix_float4x4)leftMultiplyMatrixA:(matrix_float4x4)matrixA matrixB:(matrix_float4x4)matrixB;

+(matrix_float4x4)makeTranslateX:(float)x y:(float)y z:(float)z;

+(matrix_float4x4)makeScaleX:(float)x y:(float)y z:(float)z;

+(matrix_float4x4)makeRotateX:(float)x y:(float)y z:(float)z degree:(float)degree;

@end
