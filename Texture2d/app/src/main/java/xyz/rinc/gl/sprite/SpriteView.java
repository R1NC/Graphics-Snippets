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

public class SpriteView extends GLSurfaceView {

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
    }

    void setSprite(final Sprite sprite) {
        setRenderer(new GLSpriteRenderer(sprite));
        setRenderMode(RENDERMODE_WHEN_DIRTY);
    }


    private class GLSpriteRenderer implements GLSurfaceView.Renderer {

        private Sprite sprite;

        GLSpriteRenderer(Sprite sprite) {
            this.sprite = sprite;
        }

        @Override
        public void onSurfaceCreated(GL10 unused, EGLConfig config) {
            GLES20.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

            if (sprite != null) {
                sprite.onSurfaceCreated(unused, config);
            }
        }

        @Override
        public void onSurfaceChanged(GL10 unused, int width, int height) {
            // Set the OpenGL viewport to the same size as the surface.
            GLES20.glViewport(0, 0, width, height);

            if (sprite != null) {
                sprite.onSurfaceChanged(unused, width, height);
            }
        }

        @Override
        public void onDrawFrame(GL10 unused) {
            GLES20.glClear(GLES20.GL_DEPTH_BUFFER_BIT | GLES20.GL_COLOR_BUFFER_BIT);

            if (sprite != null && sprite.bitmap != null) {
                sprite.onDrawFrame(unused);
            }
        }
    }
}
