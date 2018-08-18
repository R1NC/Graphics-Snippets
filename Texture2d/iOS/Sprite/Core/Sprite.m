//
//  Sprite.m
//  Sprite
//
//  Created by Rinc Liu on 7/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "Sprite.h"
#import "GLUtil.h"

const GLfloat VERTEX_COORDS[] = {
    -1.0f, 1.0f, 0.0f, //TL
    1.0f, 1.0f, 0.0f, //TR
    1.0f, -1.0f, 0.0f, //BR
    -1.0f, -1.0f, 0.0f, //BL
};

const GLfloat TEXTURE_COORDS[] = {
    0.0f, 0.0f, //TL
    1.0f, 0.0f, //TR
    1.0f, 1.0f, //BR
    0.0f, 1.0f, //BL
};

// Draw index order
const GLubyte INDICES[] = {
    0, 1, 2,
    0, 3, 2
};

// Position the eye behind the origin
const GLfloat CAMERA_EYE_X = 0.0f;
const GLfloat CAMERA_EYE_Y = 0.0f;
const GLfloat CAMERA_EYE_Z = 3.0f;

// We are looking toward the distance
const GLfloat CAMERA_CENTER_X = 0.0f;
const GLfloat CAMERA_CENTER_Y = 0.0f;
const GLfloat CAMERA_CENTER_Z = 0.0f;

// This is where our head would be pointing were we holding the camera.
const GLfloat CAMERA_UP_X = 0.0f;
const GLfloat CAMERA_UP_Y = 1.0f;
const GLfloat CAMERA_UP_Z = 0.0f;

@interface Sprite()
@property(nonatomic,assign) GLuint program;
@property(nonatomic,assign) GLuint vertexBuffer, textureBuffer, indexBuffer;
@property(nonatomic,assign) GLuint locPosition, locTextureCoordinate, locTexture, locProjectionMatrix, locCameraMatrix, locModelMatrix;
@property(nonatomic,assign) GLKMatrix4 projectionMatrix, cameraMatrix, modelMatrix;
@end

@implementation Sprite

-(instancetype)init {
    if ((self = [super init])) {
        _transX = 0.0f;
        _transY = 0.0f;
        _angle = 0.0f;
        _scale = 1.0f;
        
        [self loadShader];
        [self prepareBuffers];
        [self setCameraMatrix];
    }
    return self;
}

-(void)drawInRect:(CGRect)rect {
    if (_textureInfo) {
        [GLUtil bindTextureInfo:_textureInfo channel:GL_TEXTURE0 location:_locTexture];
        [self updateProjectionMatrixWithRect:rect];
        [self updateModelMatrixWithRect:rect];
        [self updateMatrices2Shader];
        [self drawElements];
    }
}

-(void)onDestroy {
    if (_program > 0) {
        //glDeleteTextures(1, _textureHandles, 0);
        glDeleteProgram(_program);
    }
    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
    }
    if (_textureBuffer) {
        glDeleteBuffers(1, &_textureBuffer);
    }
    if (_indexBuffer) {
        glDeleteBuffers(1, &_indexBuffer);
    }
}


-(void)loadShader {
    _program = [GLUtil loadVertexGLSL:@"vertex" fragmentGLSL:@"fragment"];
    if (_program > 0) {
        glUseProgram(_program);
        _locPosition = glGetAttribLocation(_program, "a_Position");
        _locTextureCoordinate = glGetAttribLocation(_program, "a_TextureCoordinate");
        _locTexture = glGetUniformLocation(_program, "u_Texture");
        _locProjectionMatrix = glGetUniformLocation(_program, "u_projectionMatrix");
        _locCameraMatrix = glGetUniformLocation(_program, "u_cameraMatrix");
        _locModelMatrix = glGetUniformLocation(_program, "u_modelMatrix");
    }
}

-(void)prepareBuffers {
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(VERTEX_COORDS), VERTEX_COORDS, GL_STATIC_DRAW);

    glGenBuffers(1, &_textureBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _textureBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(TEXTURE_COORDS), TEXTURE_COORDS, GL_STATIC_DRAW);

    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(INDICES), INDICES, GL_STATIC_DRAW);
}

-(void)setCameraMatrix {
    _cameraMatrix = GLKMatrix4MakeLookAt(CAMERA_EYE_X, CAMERA_EYE_Y, CAMERA_EYE_Z, CAMERA_CENTER_X, CAMERA_CENTER_Y, CAMERA_CENTER_Z, CAMERA_UP_X, CAMERA_UP_Y, CAMERA_UP_Z);
}

-(void)updateProjectionMatrixWithRect:(CGRect)rect {
    float ratio = rect.size.width / rect.size.height;
    float left = -ratio;
    float right = ratio;
    float bottom = -1.0f;
    float top = 1.0f;
    float nearZ = 3.0f;
    float farZ = 7.0f;
    _projectionMatrix = GLKMatrix4MakeFrustum(left, right, bottom, top, nearZ, farZ);
}

-(void)updateModelMatrixWithRect:(CGRect)rect {
    GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(_transX, _transY, 0.0);
    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(_angle) , 0.0, 0.0, -1.0);
    GLKMatrix4 scaleMatrix = GLKMatrix4Identity;
    if (_textureInfo && _textureInfo.width > 0 && _textureInfo.height > 0) {
        int targetSize = MIN(rect.size.width, rect.size.height);
        float baseScaleX = (float)_textureInfo.width / targetSize;
        float baseScaleY = (float)_textureInfo.height / targetSize;
        scaleMatrix = GLKMatrix4MakeScale(baseScaleX * _scale, baseScaleY * _scale, 1.0);
    }
    _modelMatrix = GLKMatrix4Multiply(translateMatrix, rotateMatrix);
    _modelMatrix = GLKMatrix4Multiply(_modelMatrix, scaleMatrix);
}

-(void)updateMatrices2Shader {
    glUniformMatrix4fv(_locProjectionMatrix, 1, GL_FALSE, _projectionMatrix.m);
    glUniformMatrix4fv(_locCameraMatrix, 1, GL_FALSE, _cameraMatrix.m);
    glUniformMatrix4fv(_locModelMatrix, 1, GL_FALSE, _modelMatrix.m);
}

-(void)drawElements {
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glVertexAttribPointer(_locPosition, 3, GL_FLOAT, GL_FALSE, 0, (void*)NULL);
    glEnableVertexAttribArray(_locPosition);
    
    glBindBuffer(GL_ARRAY_BUFFER, _textureBuffer);
    glVertexAttribPointer(_locTextureCoordinate, 2, GL_FLOAT, GL_FALSE, 0, (void*)NULL);
    glEnableVertexAttribArray(_locTextureCoordinate);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(INDICES)/sizeof(GLubyte), GL_UNSIGNED_BYTE, (void*)NULL);
    
    glDisableVertexAttribArray(_locPosition);
    glDisableVertexAttribArray(_locTextureCoordinate);
}

@end
