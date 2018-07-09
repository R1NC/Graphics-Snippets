package xyz.rinc.gl.sprite;

import android.graphics.Bitmap;
import android.opengl.GLES20;
import android.opengl.Matrix;

import java.nio.FloatBuffer;
import java.nio.ShortBuffer;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

/**
 * Created by rincliu on 20180703.
 */

public class Sprite {

    private static final String VERTEX_SHADER_CODE = "" +
            "uniform mat4 u_mvpMatrix;" +
            "attribute vec4 a_Position;" +
            "attribute vec2 a_TexCoordinate;" +
            "varying vec2 v_TexCoordinate;" +
            "void main() {" +
            "gl_Position = u_mvpMatrix * a_Position;" +
            "v_TexCoordinate = a_TexCoordinate;" +
            "}";

    private static final String FRAGMENT_SHADER_CODE = "" +
            "precision mediump float;" +
            "uniform sampler2D u_Texture;" +
            "varying vec2 v_TexCoordinate;" +
            "void main() {" +
            "gl_FragColor = texture2D(u_Texture, v_TexCoordinate);" +
            "}";

    private static final float[] VERTEX_COORDS = {
            -1.0f, 1.0f, 0.0f, //top left
            1.0f, 1.0f, 0.0f, //top right
            1.0f, -1.0f, 0.0f, //bottom right
            -1.0f, -1.0f, 0.0f, //bottom left
    };

    // Mapping coordinates for the vertices
    private static final float[] TEXTURE_COORDS = {
            0.0f, 0.0f, //top left
            1.0f, 0.0f, //top right
            1.0f, 1.0f, //bottom right
            0.0f, 1.0f, //bottom left
    };

    // Draw two triangles
    private static final short[] DRAW_ORDER = {0, 1, 2, 0, 3, 2};

    // Position the eye behind the origin
    private static final float LOOK_EYE_X = 0.0f;
    private static final float LOOK_EYE_Y = 0.0f;
    private static final float LOOK_EYE_Z = 3f;

    // We are looking toward the distance
    private static final float LOOK_CENTER_X = 0.0f;
    private static final float LOOK_CENTER_Y = 0.0f;
    private static final float LOOK_CENTER_Z = 0.0f;

    // This is where our head would be pointing were we holding the camera.
    private static final float LOOK_UP_X = 0.0f;
    private static final float LOOK_UP_Y = 1.0f;
    private static final float LOOK_UP_Z = 0.0f;

    private FloatBuffer vertexBuffer;
    private FloatBuffer textureBuffer;
    private ShortBuffer drawOrderBuffer;

    private int mPositionHandle;
    private int mTextureCoordinateHandle;
    private int mMVPMatrixHandle;

    private final float[] mProjMatrix = new float[16];
    private final float[] mViewMatrix = new float[16];
    private final float[] mModelViewProjMatrix = new float[16];
    private float[] mModelMatrix = new float[16];

    private int viewWidth, viewHeight, imgWidth, imgHeight;

    //Declare as volatile because we are updating it from another thread
    volatile float angle, scaleX = 1.f, scaleY = 1.f, transX, transY;
    volatile Bitmap bitmap;

    Sprite() {
    }

    void onSurfaceCreated(GL10 unused, EGLConfig config) {
        //Prepare byte buffers
        vertexBuffer = GLUtil.prepareFloatBuffer(VERTEX_COORDS);
        textureBuffer = GLUtil.prepareFloatBuffer(TEXTURE_COORDS);
        drawOrderBuffer = GLUtil.prepareShortBuffer(DRAW_ORDER);

        //Load shader program
        final int shaderProgram = GLUtil.loadShader(VERTEX_SHADER_CODE, FRAGMENT_SHADER_CODE);
        GLES20.glUseProgram(shaderProgram);

        //Prepare attributes and texture handles
        mPositionHandle = GLES20.glGetAttribLocation(shaderProgram, "a_Position");
        mTextureCoordinateHandle = GLES20.glGetAttribLocation(shaderProgram, "a_TexCoordinate");
        mMVPMatrixHandle = GLES20.glGetUniformLocation(shaderProgram, "u_mvpMatrix");

        // Generate texture2d and set parameters
        GLUtil.genTexture2d(1);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_MIRRORED_REPEAT);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_MIRRORED_REPEAT);
        // https://learnopengl.com/Getting-started/Textures
        //
        // GL_NEAREST (also known as nearest neighbor filtering) is the default texture filtering method of OpenGL.
        // When set to GL_NEAREST, OpenGL selects the pixel which center is closest to the texture coordinate.
        //
        // GL_LINEAR (also known as (bi)linear filtering) takes an interpolated value from the texture coordinate's neighboring texels,
        // approximating a color between the texels. The smaller the distance from the texture coordinate to a texel's center,
        // the more that texel's color contributes to the sampled color.
        //
        // GL_NEAREST results in blocked patterns where we can clearly see the pixels that form the texture
        // while GL_LINEAR produces a smoother pattern where the individual pixels are less visible.
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);

        // Set the view matrix. This matrix can be said to represent the camera position.
        // NOTE: In OpenGL 1, a ModelView matrix is used, which is a combination of a model and
        // view matrix. In OpenGL 2, we can keep track of these matrices separately if we choose.
        Matrix.setLookAtM(mViewMatrix, 0, LOOK_EYE_X, LOOK_EYE_Y, LOOK_EYE_Z, LOOK_CENTER_X, LOOK_CENTER_Y, LOOK_CENTER_Z, LOOK_UP_X, LOOK_UP_Y, LOOK_UP_Z);
    }

    void onSurfaceChanged(GL10 unused, int width, int height) {
        viewWidth = width;
        viewHeight = height;

        // Create a new perspective projection matrix. The height will stay the same
        // while the width will vary as per aspect ratio.
        final float ratio = (float) width / height;
        final float left = -ratio;
        final float right = ratio;
        final float bottom = -1.0f;
        final float top = 1.0f;
        final float near = 3.0f;
        final float far = 7.0f;

        Matrix.frustumM(mProjMatrix, 0, left, right, bottom, top, near, far);
    }

    void onDrawFrame(GL10 unused) {
        if (bitmap != null && !bitmap.isRecycled()) {
            imgWidth = bitmap.getWidth();
            imgHeight = bitmap.getHeight();
        }
        updateMatrices();
        draw();
    }

    private void updateMatrices() {
        Matrix.setIdentityM(mModelMatrix, 0);

        Matrix.translateM(mModelMatrix, 0, transX, transY, 0);

        Matrix.rotateM(mModelMatrix, 0, angle, 0, 0, -1.0f);

        if (imgWidth > 0 && imgHeight > 0) {
            float baseScaleX = 1.f, baseScaleY = 1.f;
            if (viewWidth > viewHeight) {
                baseScaleX = (float)imgWidth / viewHeight;
                baseScaleY = (float)imgHeight / viewHeight;
            } else {
                baseScaleX = (float)imgWidth / viewWidth;
                baseScaleY = (float)imgHeight / viewWidth;
            }
            Matrix.scaleM(mModelMatrix, 0, baseScaleX * scaleX, baseScaleY * scaleY, 1.0f);
        }

        // This multiplies the view matrix by the model matrix, and stores the result in the MVP matrix
        // (which currently contains model * view).
        Matrix.multiplyMM(mModelViewProjMatrix, 0, mViewMatrix, 0, mModelMatrix, 0);

        // This multiplies the modelview matrix by the projection matrix, and stores the result in the MVP matrix
        // (which now contains model * view * projection).
        Matrix.multiplyMM(mModelViewProjMatrix, 0, mProjMatrix, 0, mModelViewProjMatrix, 0);
    }

    private void draw() {
        GLUtil.setBitmap2Texture2d(0, bitmap);

        GLES20.glVertexAttribPointer(mPositionHandle, 3, GLES20.GL_FLOAT, false, 0, vertexBuffer);
        GLES20.glVertexAttribPointer(mTextureCoordinateHandle, 2, GLES20.GL_FLOAT, false, 0, textureBuffer);

        GLES20.glEnableVertexAttribArray(mPositionHandle);
        GLES20.glEnableVertexAttribArray(mTextureCoordinateHandle);

        //Apply the projection and view transformation
        GLES20.glUniformMatrix4fv(mMVPMatrixHandle, 1, false, mModelViewProjMatrix, 0);

        //GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, VERTEX_COORDS.length / 3);
        GLES20.glDrawElements(GLES20.GL_TRIANGLE_STRIP, DRAW_ORDER.length, GLES20.GL_UNSIGNED_SHORT, drawOrderBuffer);

        GLES20.glDisableVertexAttribArray(mPositionHandle);
        GLES20.glDisableVertexAttribArray(mTextureCoordinateHandle);
    }
}
