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
    private boolean frameAudio, frameLoop;
    private float frameScale = 1.f;

    private MediaPlayer audioPlayer;
    private SpriteView spriteView;
    private boolean playing, stop;
    private AssetManager assetManager;

    private SpritePlayer() {}

    public SpritePlayer(SpriteView spriteView) {
        assetManager = spriteView.getContext().getAssets();
        this.spriteView = spriteView;
    }

    private void start() {
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
                            for (int i = 0; i < spriteView.sprites.size(); i++) {
                                boolean multi = spriteView.sprites.size() > 1;
                                Sprite sprite = spriteView.sprites.get(i);
                                if (frameIndex == 0) {
                                    int n = 6;
                                    int randomX = ((int)(Math.random() * n)) * 2 - n;
                                    int randomY = ((int)(Math.random() * n)) * 2 - n;
                                    sprite.transX = multi ? 0.3f * randomX : 0;
                                    sprite.transY = multi ? 0.3f * randomY : 0;
                                    Log.d("@_@", randomX+","+randomY + " " + sprite.transX + "," + sprite.transY);
                                }
                                sprite.scale = frameScale;
                                InputStream is = assetManager.open(frameFolder + "/" + (frameIndex % frameCount) + ".png");
                                if (is != null) {
                                    sprite.bitmap = BitmapFactory.decodeStream(is);
                                }
                            }
                            spriteView.requestRender();

                            Thread.sleep(16);

                            frameIndex++;
                        }
                    } catch (Exception e) {}

                    if (!frameLoop && frameIndex >= frameCount) {
                        frameIndex = 0;
                        for (int i = 0; i < spriteView.sprites.size(); i++) {
                            Sprite sprite = spriteView.sprites.get(i);
                            sprite.scale = 0;
                        }
                        spriteView.requestRender();

                        stopAudioPlayer(true);

                        break;
                    }
                }
                playing = false;
            }
        }.start();
    }

    private void stopAudioPlayer(boolean release) {
        if (frameAudio && audioPlayer != null && audioPlayer.isPlaying()) {
            audioPlayer.pause();
            if (release) {
                audioPlayer.release();
                audioPlayer = null;
            }
        }
    }

    private void stop() {
        stop = true;
        stopAudioPlayer(false);
    }

    private void release() {
        for (Sprite sprite : spriteView.sprites) {
            sprite.release();
        }
        spriteView.sprites.clear();
        stopAudioPlayer(true);
    }

    public void onPause() {
        spriteView.onPause();
        stop();
    }

    public void onResume() {
        spriteView.onResume();
        start();
    }

    public void onDestroy() {
        release();
    }

    public void setParameters(String assetFolder, float scale, int particles, boolean loop) {
        release();

        try {
            String[] files;
            if (assetFolder == null || (files = assetManager.list(assetFolder)) == null || particles <= 0) return;

            for (int i = 0; i < particles; i++) {
                spriteView.sprites.add(new Sprite());
            }
            spriteView.notifyDataSetChanged();

            frameIndex = 0;
            frameFolder = assetFolder;
            frameCount = 0;
            frameScale = scale;
            frameAudio = false;
            frameLoop = loop;
            for (String f : files) {
                if (f.endsWith(".png")) {
                    frameCount++;
                }
                if (f.endsWith(".mp3")) {
                    frameAudio = true;
                }
            }

            if (frameAudio) {
                AssetFileDescriptor afd = assetManager.openFd(frameFolder + "/audio.mp3");
                if (afd != null) {
                    audioPlayer = new MediaPlayer();
                    audioPlayer.setLooping(true);
                    audioPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
                    audioPlayer.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
                        @Override
                        public void onPrepared(MediaPlayer mediaPlayer) {
                            audioPlayer.start();
                            start();
                        }
                    });
                    audioPlayer.prepareAsync();
                }
            } else {
                start();
            }
        } catch (Exception e) {}
    }
}
