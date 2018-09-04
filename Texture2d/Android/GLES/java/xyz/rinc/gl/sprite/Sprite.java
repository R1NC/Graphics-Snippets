package xyz.rinc.gl.sprite;

import android.graphics.Bitmap;
import android.opengl.ETC1Util;
import android.opengl.GLES20;
import android.opengl.Matrix;

import java.nio.FloatBuffer;
import java.nio.ShortBuffer;

public class Sprite {

    public enum TextureType {
        UNKNOWN, PNG, ETC1
    }

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
    private static final short[] INDICES = {0, 1, 2, 0, 3, 2};

    // Position the eye behind the origin
    private static final float CAMERA_EYE_X = 0.0f;
    private static final float CAMERA_EYE_Y = 0.0f;
    private static final float CAMERA_EYE_Z = 3f;

    // We are looking toward the distance
    private static final float CAMERA_CENTER_X = 0.0f;
    private static final float CAMERA_CENTER_Y = 0.0f;
    private static final float CAMERA_CENTER_Z = 0.0f;

    // This is where our head would be pointing were we holding the camera.
    private static final float CAMERA_UP_X = 0.0f;
    private static final float CAMERA_UP_Y = 1.0f;
    private static final float CAMERA_UP_Z = 0.0f;

    private FloatBuffer vertexBuffer;
    private FloatBuffer textureBuffer;
    private ShortBuffer indexBuffer;

    private int program;

    private int locETC;
    private int locPosition;
    private int locTextureCoordinate;
    private int locProjectionMatrix, locCameraMatrix, locModelMatrix;
    private int[] textureHandles;

    private final float[] projectionMatrix = new float[16];
    private final float[] cameraMatrix = new float[16];
    private final float[] modelMatrix = new float[16];

    private int viewWidth, viewHeight;

    private Context context;

    //Declare as volatile because we are updating it from another thread
    volatile float angle, scale = 1.f, transX, transY;
    private int imgWidth, imgHeight;
    volatile Bitmap png;
    volatile ETC1Util.ETC1Texture etc1;
    volatile TextureType textureType = TextureType.UNKNOWN;

    Sprite(Context context) {
        this.context = context;
    }

    void onSurfaceCreated() {
        loadShader();
        prepareBuffers();
        setCameraMatrix();
    }

    void onSurfaceChanged(int width, int height) {
        viewWidth = width;
        viewHeight = height;
        updateProjectionMatrix(width, height);
    }

    void onDrawFrame() {
        if (textureType == TextureType.PNG && png != null && !png.isRecycled()) {
            imgWidth = png.getWidth();
            imgHeight = png.getHeight();
            GLUtil.setBitmap2Texture2d(0, png);
        } else if (textureType == TextureType.ETC1 && etc1 != null) {
            imgWidth = etc1.getWidth();
            imgHeight = etc1.getHeight() / 2;
            GLUtil.bindTextureETC1(0, etc1);
        }

        updateModelMatrix();

        updateUniform2Shader();

        drawElements();
    }

    void release() {
        if (program > 0) {
            GLES20.glDeleteProgram(program);
            GLES20.glDeleteTextures(1, textureHandles, 0);
        }
        vertexBuffer.clear();
        textureBuffer.clear();
        indexBuffer.clear();
        if (png != null) {
            if (!png.isRecycled()) {
                png.recycle();
            }
            png = null;
        }
        if (etc1 != null) {
            if (etc1.getData() != null) {
                etc1.getData().clear();
            }
            etc1 = null;
        }
    }

    void loadShader() {
        program = GLUtil.loadShaderAsset(context, "SpriteVertex.glsl", "SpriteFragment.glsl");
        if (program > 0) {
            GLES20.glUseProgram(program);
            locETC = GLES20.glGetAttribLocation(program, "u_ETC");
            locPosition = GLES20.glGetAttribLocation(program, "a_Position");
            locTextureCoordinate = GLES20.glGetAttribLocation(program, "a_TextureCoordinate");
            locProjectionMatrix = GLES20.glGetUniformLocation(program, "u_projectionMatrix");
            locCameraMatrix = GLES20.glGetUniformLocation(program, "u_cameraMatrix");
            locModelMatrix = GLES20.glGetUniformLocation(program, "u_modelMatrix");
            textureHandles = GLUtil.genTexture2d(1);
        }
    }

    private void prepareBuffers() {
        vertexBuffer = GLUtil.prepareFloatBuffer(VERTEX_COORDS);
        textureBuffer = GLUtil.prepareFloatBuffer(TEXTURE_COORDS);
        indexBuffer = GLUtil.prepareShortBuffer(INDICES);
    }

    private void setCameraMatrix() {
        // Set the camera matrix. This matrix can be said to represent the camera position.
        // NOTE: In OpenGL 1, a ModelView matrix is used, which is a combination of a model and
        // view matrix. In OpenGL 2, we can keep track of these matrices separately if we choose.
        Matrix.setLookAtM(cameraMatrix, 0, CAMERA_EYE_X, CAMERA_EYE_Y, CAMERA_EYE_Z, CAMERA_CENTER_X, CAMERA_CENTER_Y, CAMERA_CENTER_Z, CAMERA_UP_X, CAMERA_UP_Y, CAMERA_UP_Z);
    }

    private void updateProjectionMatrix(int width, int height) {
        // Create a new perspective projection matrix. The height will stay the same
        // while the width will vary as per aspect ratio.
        final float ratio = (float) width / height;
        final float left = -ratio;
        final float right = ratio;
        final float bottom = -1.0f;
        final float top = 1.0f;
        final float nearZ = 3.0f;
        final float farZ = 7.0f;
        Matrix.frustumM(projectionMatrix, 0, left, right, bottom, top, nearZ, farZ);
    }

    private void updateModelMatrix() {
        Matrix.setIdentityM(modelMatrix, 0);
        Matrix.translateM(modelMatrix, 0, transX, transY, 0);
        Matrix.rotateM(modelMatrix, 0, angle, 0, 0, -1.0f);
        if (imgWidth > 0 && imgHeight > 0) {
            int targetSize = Math.min(viewWidth, viewHeight);
            float baseScaleX = (float)imgWidth / targetSize;
            float baseScaleY = (float)imgHeight / targetSize;
            Matrix.scaleM(modelMatrix, 0, baseScaleX * scale, baseScaleY * scale, 1.0f);
        }
    }

    private void updateUniform2Shader() {
        GLES20.glUniformMatrix4fv(locProjectionMatrix, 1, false, projectionMatrix, 0);
        GLES20.glUniformMatrix4fv(locCameraMatrix, 1, false, cameraMatrix, 0);
        GLES20.glUniformMatrix4fv(locModelMatrix, 1, false, modelMatrix, 0);
        GLES20.glUniform1f(locETC, textureType == TextureType.ETC1 ? 1.0f : 0.0f);
    }

    private void drawElements() {
        try {
            GLES20.glVertexAttribPointer(locPosition, 3, GLES20.GL_FLOAT, false, 0, vertexBuffer);
            GLES20.glEnableVertexAttribArray(locPosition);

            GLES20.glVertexAttribPointer(locTextureCoordinate, 2, GLES20.GL_FLOAT, false, 0, textureBuffer);
            GLES20.glEnableVertexAttribArray(locTextureCoordinate);

            GLES20.glDrawElements(GLES20.GL_TRIANGLE_STRIP, INDICES.length, GLES20.GL_UNSIGNED_SHORT, indexBuffer);

            GLES20.glDisableVertexAttribArray(locPosition);
            GLES20.glDisableVertexAttribArray(locTextureCoordinate);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
