package xyz.rinc.gl.sprite;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.PixelFormat;
import android.opengl.ETC1;
import android.opengl.ETC1Util;
import android.opengl.GLES10;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.opengl.GLUtils;
import android.text.TextUtils;
import android.util.Log;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.InputStream;
import java.lang.StringBuffer;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.ShortBuffer;

import static javax.microedition.khronos.opengles.GL10.GL_TEXTURE_2D;

public class GLUtil {

    private static final String TAG = "GLUtil";

    // PowerVR Texture compression constants
    /*public static final int GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG = 0x8C00;
    public static final int GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG = 0x8C01;
    public static final int GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG = 0x8C02;
    public static final int GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG = 0x8C03;*/

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
                    GLES20.glBindTexture(GL_TEXTURE_2D, h);
                    GLES20.glTexParameteri(GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_MIRRORED_REPEAT);
                    GLES20.glTexParameteri(GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_MIRRORED_REPEAT);
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
                    GLES20.glTexParameteri(GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST);
                    GLES20.glTexParameteri(GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
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
        GLUtils.texImage2D(GL_TEXTURE_2D, 0, bitmap, 0);
        bitmap.recycle();
    }

    /*public static ByteBuffer loadTexturePVRTCFromAsset(String asset, AssetManager assetManager) {
        if (TextUtils.isEmpty(asset) || assetManager == null) return null;
        try {
            InputStream stream = assetManager.open(asset);
            byte[] buffer = new byte[stream.available()];
            stream.read(buffer);
            stream.close();
            int offset = 67; // 52 bit = header, 15 bit = metadata
            ByteBuffer bf = ByteBuffer.wrap(buffer, offset, buffer.length-offset);
            bf.order(ByteOrder.LITTLE_ENDIAN);
            return bf;
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }*/

    public static ETC1Util.ETC1Texture loadTextureETC1(InputStream is) {
        if (is == null) return null;
        try {
            return ETC1Util.createTexture(is);
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }

    /*public static void bindTexturePVRTC(int texture2dIndex, ByteBuffer data) {
        if (data == null) return;

        long version     = data.getInt(0) & 0xFFFFFFFFL;
        long flags       = data.getInt(4);
        long pixelFormat = data.getLong(8);
        long colorF      = data.getInt(16);
        long chanel      = data.getInt(20);
        int height       = data.getInt(24);
        int width        = data.getInt(28);
        long depth       = data.getInt(32);
        long nsurf       = data.getInt(36);
        long nface       = data.getInt(40);
        long mipC        = data.getInt(44);
        long mSize       = data.getInt(48);
        long fourCC      = data.getInt(52)& 0xFFFFFFFFL;
        long key         = data.getInt(56)& 0xFFFFFFFFL;
        long dataSize    = data.getInt(60)& 0xFFFFFFFFL;

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0 + texture2dIndex);
        GLES20.glCompressedTexImage2D(GL_TEXTURE_2D, 0, GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG, 1024, 1024, 0, data.capacity(), data);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);

        data.clear();
    }*/

    public static void bindTextureETC1(int texture2dIndex, ETC1Util.ETC1Texture texture) {
        int width = texture.getWidth();
        int height = texture.getHeight();
        ByteBuffer data = texture.getData();
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0 + texture2dIndex);
        GLES10.glCompressedTexImage2D(GLES10.GL_TEXTURE_2D, 0, ETC1.ETC1_RGB8_OES, width, height, 0, data.remaining(), data);
        data.clear();
    }

    /*public static boolean supportTexturePVRTC() {
        String extensions = GLES20.glGetString(GL10.GL_EXTENSIONS);
        return extensions.contains("GL_IMG_texture_compression_pvrtc");
    }*/

    public static int loadShaderAsset(Context context, String vertexShaderAsset, String fragmentShaderAsset) {
        String vertexShader = stringFromAsset(context, vertexShaderAsset);
        String fragmentShader = stringFromAsset(context, fragmentShaderAsset);
        if (!TextUtils.isEmpty(vertexShader) && !TextUtils.isEmpty(fragmentShader)) {
            return loadShader(vertexShader, fragmentShader);
        }
        return -1;
    }

    private static String stringFromAsset(Context context, String assetFile) {
        StringBuffer sBuffer = new StringBuffer();
        BufferedReader reader = null;
        try {
            reader = new BufferedReader(new InputStreamReader(context.getAssets().open(assetFile)));
            String line;
            while (!TextUtils.isEmpty(line = reader.readLine())) {
                sBuffer.append(line);
            }
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (reader != null) {
                try {
                    reader.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            return sBuffer.toString();
        }
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
