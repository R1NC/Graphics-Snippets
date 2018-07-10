package xyz.rinc.gl.sprite;

import android.content.Context;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.util.AttributeSet;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

/**
 * Created by rincliu on 20180703.
 */

public class SpriteView extends GLSurfaceView implements GLSurfaceView.Renderer {

    final ArrayList<Sprite> sprites = new ArrayList<>();

    private int width, height;

    public SpriteView(Context context) {
        super(context);
        init();
    }

    public SpriteView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    private void init() {
        GLUtil.makeSurfaceViewTransparent(this);
        setRenderer(this);
        setRenderMode(RENDERMODE_WHEN_DIRTY);
    }

    void notifyDataSetChanged() {
        if (sprites != null) {
            for (final Sprite sprite : sprites) {
                // OpenGL API must Run on GLThread
                queueEvent(new Runnable(){
                    @Override
                    public void run() {
                        sprite.onSurfaceCreated();
                        sprite.onSurfaceChanged(width, height);
                    }
                });
            }
        }
    }

    @Override
    public void onSurfaceCreated(GL10 unused, EGLConfig config) {
        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

        if (sprites != null) {
            for (Sprite sprite : sprites) {
                sprite.onSurfaceCreated();
            }
        }
    }

    @Override
    public void onSurfaceChanged(GL10 unused, int width, int height) {
        // Set the OpenGL viewport to the same size as the surface.
        GLES20.glViewport(0, 0, width, height);

        this.width = width;
        this.height = height;

        if (sprites != null) {
            for (Sprite sprite : sprites) {
                sprite.onSurfaceChanged(width, height);
            }
        }
    }

    @Override
    public void onDrawFrame(GL10 unused) {
        GLES20.glClear(GLES20.GL_DEPTH_BUFFER_BIT | GLES20.GL_COLOR_BUFFER_BIT);

        if (sprites != null) {
            for (Sprite sprite : sprites) {
                if (sprite.bitmap != null && !sprite.bitmap.isRecycled()) {
                    sprite.onDrawFrame();
                }
            }
        }
    }
}
