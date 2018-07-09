package xyz.rinc.gl.sprite;

import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.graphics.BitmapFactory;
import android.media.MediaPlayer;

import java.io.InputStream;

/**
 * Created by rincliu on 20180705.
 */

public class SpritePlayer {

    private String frameFolder;
    private int frameIndex = 0, frameCount;
    private boolean frameAudio;
    private float frameScale = 1.f;

    private MediaPlayer audioPlayer;
    private SpriteView spriteView;
    private Sprite sprite;
    private boolean playing, stop;
    private AssetManager assetManager;

    private SpritePlayer() {}

    public SpritePlayer(SpriteView spriteView) {
        sprite = new Sprite();
        spriteView.setSprite(sprite);
        this.spriteView = spriteView;
        assetManager = spriteView.getContext().getAssets();
    }

    public void start() {
        stop = false;
        if (frameAudio && audioPlayer != null && !audioPlayer.isPlaying()) {
            audioPlayer.start();
        }
        if (playing) return;
        playing = true;
        new Thread() {
            @Override
            public void run() {
                while (!stop) {
                    try {
                        if (frameFolder != null && frameCount > 0) {
                            InputStream is = assetManager.open(frameFolder + "/" + (frameIndex % frameCount) + ".png");
                            if (is != null) {
                                sprite.bitmap = BitmapFactory.decodeStream(is);
                                sprite.scaleX = frameScale;
                                sprite.scaleY = frameScale;
                                spriteView.requestRender();
                            }

                            Thread.sleep(16);

                            frameIndex++;
                        }
                    } catch (Exception e) {}
                }
                playing = false;
            }
        }.start();
    }

    public void stop() {
        stop = true;
        if (frameAudio && audioPlayer != null && audioPlayer.isPlaying()) {
            audioPlayer.pause();
        }
    }

    public void setParameters(String assetFolder, float scale) {
        try {
            String[] files;
            if (assetFolder == null || assetFolder.equals(frameFolder) || (files = assetManager.list(assetFolder)) == null) return;
            frameIndex = 0;
            frameFolder = assetFolder;
            frameCount = 0;
            frameScale = scale;
            frameAudio = false;
            for (String f : files) {
                if (f.endsWith(".png")) {
                    frameCount++;
                }
                if (f.endsWith(".mp3")) {
                    frameAudio = true;
                }
            }

            if (audioPlayer != null && audioPlayer.isPlaying()) {
                audioPlayer.stop();
                audioPlayer.release();
                audioPlayer = null;
            }
            if (frameAudio) {
                AssetFileDescriptor afd = assetManager.openFd(frameFolder + "/audio.mp3");
                if (afd != null) {
                    audioPlayer = new MediaPlayer();
                    audioPlayer.setLooping(true);
                    audioPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
                    audioPlayer.prepare();
                }
            }
        } catch (Exception e) {}
    }
}
