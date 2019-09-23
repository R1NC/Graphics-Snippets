//
//  MatrixUtil.m
//  SpriteSDK
//
//  Created by Rinc Liu on 1/9/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "MatrixUtil.h"

#define degree2radius(d) (d * M_PI / 180.f)
#define sind(d) sin(degree2radius(d))
#define cosd(d) cos(degree2radius(d))

@implementation MatrixUtil

+(matrix_float4x4)makeIdentity {
    matrix_float4x4 m = {
        .columns = {
            {1.0f, 0.0f, 0.0f, 0.0f},
            {0.0f, 1.0f, 0.0f, 0.0f},
            {0.0f, 0.0f, 1.0f, 0.0f},
            {0.0f, 0.0f, 0.0f, 1.0f}
        }
    };
    return m;
}

+(matrix_float4x4)leftMultiplyMatrixA:(matrix_float4x4)mA matrixB:(matrix_float4x4)mB {
    matrix_float4x4 m = {};
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            for (int k = 0; k < 4; k++) {
                m.columns[i][j] += mB.columns[i][k] * mA.columns[k][j];
            }
        }
    }
    return m;
}

+(matrix_float4x4)makeTranslateX:(float)x y:(float)y z:(float)z {
    matrix_float4x4 m = {
        .columns = {
            {1.0f,  0.0f,   0.0f,   0.0f},
            {0.0f,  1.0f,   0.0f,   0.0f},
            {0.0f,  0.0f,   1.0f,   0.0f},
            {x,     y,      z,      1.0f}
        }
    };
    return m;
}

+(matrix_float4x4)makeScaleX:(float)x y:(float)y z:(float)z {
    matrix_float4x4 m = {
        .columns = {
            {x,     0.0f,   0.0f,   0.0f},
            {0.0f,  y,      0.0f,   0.0f},
            {0.0f,  0.0f,   z,      0.0f},
            {0.0f,  0.0f,   0.0f,   1.0f}
        }
    };
    return m;
}

+(matrix_float4x4)makeRotateX:(float)x y:(float)y z:(float)z degree:(float)degree {
    float cos = cosd(degree), sin = sind(degree);
    matrix_float4x4 m = {
        .columns = {
            {cos + x * x * (1 - cos),       x * y * (1 - cos) - z * sin,    x * z * (1 - cos) + y * sin,    0.0f},
            {x * y * (1 - cos) + z * sin,   cos + y * y * (1 - cos),        y * z * (1 - cos) - x * sin,    0.0f},
            {x * z * (1 - cos) - y * sin,   y * z * (1 - cos) + x * sin,    cos + z * z * (1 - cos),        0.0f},
            {0.0f,                          0.0f,                           0.0f,                           1.0f}
        }
    };
    return m;
}

@end
