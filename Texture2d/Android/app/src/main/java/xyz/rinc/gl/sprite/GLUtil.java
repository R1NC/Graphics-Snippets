package xyz.rinc.gl.sprite;

import android.graphics.Bitmap;
import android.graphics.PixelFormat;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.opengl.GLUtils;
import android.util.Log;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.ShortBuffer;

public class GLUtil {

    private static final String TAG = "GLUtil";

    private GLUtil() {}

    public static void makeSurfaceViewTransparent(GLSurfaceView glSurfaceView) {
        glSurfaceView.setZOrderOnTop(true);
        glSurfaceView.setEGLContextClientVersion(2);
        glSurfaceView.setEGLConfigChooser(8, 8, 8, 8, 16, 0);
        glSurfaceView.getHolder().setFormat(PixelFormat.TRANSLUCENT);
    }

    public static FloatBuffer prepareFloatBuffer(float[] src) {
        FloatBuffer buffer = ByteBuffer.allocateDirect(src.length * 4).order(ByteOrder.nativeOrder()).asFloatBuffer();
        buffer.put(src).position(0);
        return buffer;
    }

    public static ShortBuffer prepareShortBuffer(short[] src) {
        ShortBuffer buffer = ByteBuffer.allocateDirect(src.length * 2).order(ByteOrder.nativeOrder()).asShortBuffer();
        buffer.put(src).position(0);
        return buffer;
    }

    public static int[] genTexture2d(int n) {
        if (n > 0) {
            final int[] textureHandles = new int[n];
            GLES20.glGenTextures(n, textureHandles, 0);
            for (int h : textureHandles) {
                if (h != 0) {
                    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, h);
                }
            }
            return textureHandles;
        }
        return null;
    }

    // [GL_TEXTURE0,GL_TEXTURE31]
    public static void setBitmap2Texture2d(int texture2dIndex, Bitmap bitmap) {
        if (bitmap == null || bitmap.isRecycled() || texture2dIndex < 0 || texture2dIndex > 31) return;
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0 + texture2dIndex);
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0);
        bitmap.recycle();
    }

    public static int loadShader(String vertexShader, String fragmentShader) {
        int iVShader;
        int iFShader;
        int iProgId;
        int[] link = new int[1];
        iVShader = loadShader(vertexShader, GLES20.GL_VERTEX_SHADER);
        if (iVShader == 0) {
            Log.d(TAG, "Load Vertex Shader Failed");
            return 0;
        }
        iFShader = loadShader(fragmentShader, GLES20.GL_FRAGMENT_SHADER);
        if(iFShader == 0) {
            Log.d(TAG, "Load Fragment Shader Failed");
            return 0;
        }

        iProgId = GLES20.glCreateProgram();

        GLES20.glAttachShader(iProgId, iVShader);
        GLES20.glAttachShader(iProgId, iFShader);

        GLES20.glLinkProgram(iProgId);

        GLES20.glGetProgramiv(iProgId, GLES20.GL_LINK_STATUS, link, 0);
        if (link[0] <= 0) {
            Log.d(TAG,"ShaderLinking Failed");
            return 0;
        }
        GLES20.glDeleteShader(iVShader);
        GLES20.glDeleteShader(iFShader);
        return iProgId;
    }

    private static int loadShader(String strSource, int iType) {
        int[] compiled = new int[1];
        int iShader = GLES20.glCreateShader(iType);
        GLES20.glShaderSource(iShader, strSource);
        GLES20.glCompileShader(iShader);
        GLES20.glGetShaderiv(iShader, GLES20.GL_COMPILE_STATUS, compiled, 0);
        if (compiled[0] == 0) {
            Log.d(TAG, "Load Shader Failed Compilation\n" + GLES20.glGetShaderInfoLog(iShader));
            return 0;
        }
        return iShader;
    }
}
