package xyz.rinc.gl.sprite;

import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;

import java.io.InputStream;

public class SpritePlayer {

    private String frameFolder;
    private int frameIndex = 0, frameCount;
    private boolean frameAudio, frameLoop;
    private float frameScale = 1.f;
    private long frameDelay;

    private MediaPlayer audioPlayer;
    private SpriteView spriteView;
    private boolean playing, stop, destroy;
    private AssetManager assetManager;

    private Callback callback;

    private Handler handler;

    public interface Callback {
        void onStarted();
        void onPaused();
        void onResumed();
        void onLooped();
        void onStopped();
    }

    private SpritePlayer() {}

    public SpritePlayer(SpriteView spriteView) {
        assetManager = spriteView.getContext().getAssets();
        this.spriteView = spriteView;
        handler = new Handler(Looper.getMainLooper());
    }

    public void setCallback(Callback callback) {
        this.callback = callback;
    }

    private void start() {
        if (playing || frameFolder == null || frameCount <= 0 || (!frameLoop && frameIndex >= frameCount-1)) return;
        stop = false;
        if (frameAudio && audioPlayer != null && !audioPlayer.isPlaying()) {
            audioPlayer.start();
        }
        playing = true;
        if (frameIndex > 0) {
            if (callback != null)  callback.onResumed();
        }
        new Thread() {
            @Override
            public void run() {
                while (!stop && !destroy) {
                    try {
                        for (int i = 0; i < spriteView.sprites.size(); i++) {
                            Sprite sprite = spriteView.sprites.get(i);
                            String assetImage = frameFolder + "/" + (frameIndex % frameCount) + ".png";
                            sprite.bitmap = BitmapFactory.decodeStream(assetManager.open(assetImage));
                            sprite.scale = frameScale;
                        }
                        spriteView.requestRender();
                        Thread.sleep(frameDelay);
                        frameIndex++;

                        if (frameIndex >= frameCount-1) {
                            if (frameLoop) {
                                if (frameIndex % frameCount == 0) {
                                    if (callback != null) {
                                        handler.post(new Runnable() {
                                            @Override
                                            public void run() {
                                                callback.onLooped();
                                            }
                                        });
                                    }
                                }
                            } else {
                                for (int i = 0; i < spriteView.sprites.size(); i++) {
                                    Sprite sprite = spriteView.sprites.get(i);
                                    sprite.scale = 0;
                                }
                                spriteView.requestRender();
                                break;
                            }
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                if (!destroy) {
                    if (frameIndex == frameCount - 1) {
                        if (callback != null) {
                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    callback.onStopped();
                                }
                            });
                        }
                    } else {
                        if (callback != null) {
                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    callback.onPaused();
                                }
                            });
                        }
                    }
                    playing = false;
                }
            }
        }.start();
    }

    private void initAudioPlayerIfNeeded() {
        if (audioPlayer == null) {
            audioPlayer = new MediaPlayer();
            audioPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
            audioPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
                @Override
                public void onCompletion(MediaPlayer mediaPlayer) {
                    if (!frameLoop && frameIndex >= frameCount-1) {
                        stopAudioPlayer();
                        resetAudioPlayer();
                    }
                }
            });
            audioPlayer.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
                @Override
                public void onPrepared(MediaPlayer mediaPlayer) {
                    audioPlayer.start();
                    start();
                    if (callback != null) callback.onStarted();
                }
            });
        }
    }

    private void stopAudioPlayer() {
        if (frameAudio && audioPlayer != null) {
            if (audioPlayer.isPlaying()) {
                audioPlayer.pause();
            }
        }
    }

    private void resetAudioPlayer() {
        if (frameAudio && audioPlayer != null) {
            audioPlayer.reset();
        }
    }

    private void releaseAudioPlayer() {
        if (frameAudio && audioPlayer != null) {
            audioPlayer.release();
            audioPlayer = null;
        }
    }

    private void releaseSprites(boolean reset) {
        for (Sprite sprite : spriteView.sprites) {
            sprite.release();
        }
        spriteView.sprites.clear();
        if (reset) {
            spriteView.sprites.add(new Sprite());
        }
        spriteView.notifyDataSetChanged();
    }

    public void onPause() {
        spriteView.onPause();
        stopAudioPlayer();
        stop = true;
    }

    public void onResume() {
        spriteView.onResume();
        start();
    }

    public void onDestroy() {
        releaseSprites(false);
        stopAudioPlayer();
        releaseAudioPlayer();
        destroy = true;
    }

    public void play(String assetFolder, float scale) {
        play(assetFolder, scale, false, 50);
    }

    public void play(String assetFolder, float scale, boolean loop, long frameDelay) {
        if (TextUtils.isEmpty(assetFolder) || frameDelay < 0) return;

        releaseSprites(true);
        stopAudioPlayer();
        resetAudioPlayer();

        try {
            String[] files;
            if ((files = assetManager.list(assetFolder)) == null) return;

            frameIndex = 0;
            frameCount = 0;
            frameAudio = false;

            frameScale = scale;
            frameFolder = assetFolder;
            frameLoop = loop;
            this.frameDelay = frameDelay;

            for (String f : files) {
                if (f.endsWith(".png") && !f.startsWith("icon")) {
                    frameCount++;
                }
                if (f.endsWith(".mp3")) {
                    frameAudio = true;
                }
            }

            if (frameAudio) {
                AssetFileDescriptor afd = assetManager.openFd(frameFolder + "/audio.mp3");
                if (afd != null) {
                    initAudioPlayerIfNeeded();
                    audioPlayer.setLooping(frameLoop);
                    audioPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
                    audioPlayer.prepareAsync();
                }
            } else {
                start();
                if (callback != null) callback.onStarted();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
