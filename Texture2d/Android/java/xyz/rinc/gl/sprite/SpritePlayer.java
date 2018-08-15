package xyz.rinc.gl.sprite;

import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.graphics.BitmapFactory;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.HashMap;

public class SpritePlayer {

    private static final String TAG = "SpritePlayer";

    private static final String EXTENSION_PNG = ".png";
    private static final String EXTENSION_PKM = ".pkm";

    private String frameFolder;
    private int frameIndex = 0, frameCount;
    private boolean frameLoop;
    private float frameScale = 1.f;
    private long frameDuration;

    private int currentAudio = -1;
    private SpriteView spriteView;
    private boolean playing, stop, destroy;
    private AssetManager assetManager;

    private Callback callback;

    private Handler handler;

    private HashMap<Integer, MediaPlayer> audioMap;

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

    private MediaPlayer audioPlayer() {
        if (audioMap != null) {
            return audioMap.get(currentAudio);
        }
        return null;
    }

    private void startRender() {
        if (playing || frameFolder == null || frameCount <= 0 || (!frameLoop && frameIndex > frameCount-1)) return;
        stop = false;
        if (frameIndex > 0) {
            startPlayAudio();
            if (callback != null)  callback.onResumed();
        }
        new Thread() {
            @Override
            public void run() {
                while (!stop && !destroy) {
                    long t0 = System.currentTimeMillis();

                    if (audioMap != null) {
                        int a = -1;
                        for (int k : audioMap.keySet()) {
                            if (frameLoop) {
                                if (frameIndex % frameCount == k) {
                                    a = k;
                                    break;
                                }
                            } else {
                                if (frameIndex == k) {
                                    a = k;
                                    break;
                                }
                            }
                        }
                        if (a != -1) {
                            stopPlayAudio();
                            currentAudio = a;
                            startPlayAudio();
                        }
                    }

                    try {
                        for (int i = 0; i < spriteView.sprites.size(); i++) {
                            Sprite sprite = spriteView.sprites.get(i);
                            long tx = System.currentTimeMillis();
                            if (sprite.textureType == Sprite.TextureType.PNG) {
                                String assetImage = frameFolder + "/" + (frameIndex % frameCount) + EXTENSION_PNG;
                                sprite.png = BitmapFactory.decodeStream(assetManager.open(assetImage));
                                Log.d(TAG, "Load PNG "+assetImage+" cost: "+(System.currentTimeMillis()-tx));
                            } else if (sprite.textureType == Sprite.TextureType.ETC1) {
                                String assetImage = frameFolder + "/" + (frameIndex % frameCount) + EXTENSION_PKM;
                                sprite.etc1 = GLUtil.loadTextureETC1(assetManager.open(assetImage));
                                Log.d(TAG, "Load ETC1 "+assetImage+" cost: "+(System.currentTimeMillis()-tx));
                            }
                            sprite.scale = frameScale;
                        }
                        spriteView.requestRender();

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

                        long t1 = System.currentTimeMillis();
                        if (t1 - t0 < frameDuration) {
                            Thread.sleep(frameDuration + t0 - t1);
                            frameIndex++;
                        } else {
                            frameIndex += (t1 - t0) / frameDuration;
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                if (!destroy) {
                    if (frameIndex >= frameCount - 1) {
                        stopPlayAudio();
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

    private MediaPlayer createPlayer(String assetFile, boolean loop) {
        final MediaPlayer player = new MediaPlayer();
        player.setLooping(loop);
        player.setAudioStreamType(AudioManager.STREAM_MUSIC);
        try {
            AssetFileDescriptor afd = assetManager.openFd(assetFile);
            if (afd != null) {
                player.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            }
            player.prepare();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return player;
    }

    private void startPlayAudio() {
        MediaPlayer player = audioPlayer();
        if (audioMap != null && player != null) {
            if (!playing) {
                try {
                    player.start();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                playing = true;
            }
        }
    }

    private void stopPlayAudio() {
        MediaPlayer player = audioPlayer();
        if (audioMap != null && player != null) {
            if (playing) {
                try {
                    player.pause();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                playing = false;
            }
        }
    }

    private void releaseAllAudios() {
        if (audioMap != null) {
            for (int k : audioMap.keySet()) {
                MediaPlayer p = audioMap.get(k);
                if (p != null) {
                    p.release();
                }
            }
            audioMap.clear();
        }
        currentAudio = -1;
        playing = false;
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
        stopPlayAudio();
        stop = true;
    }

    public void onResume() {
        spriteView.onResume();
        startRender();
    }

    public void onDestroy() {
        releaseSprites(false);
        stopPlayAudio();
        releaseAllAudios();
        destroy = true;
    }

    public void play(String assetFolder) {
        stop = true;

        if (readFiles(assetFolder) == null) return;

        frameIndex = 0;
        frameCount = 0;
        frameFolder = assetFolder;

        releaseAllAudios();
        releaseSprites(true);

        new Thread() {
            @Override
            public void run() {
                JSONObject jo = null;
                String fc = readStrFromAssetFile(frameFolder+"/config.json");
                if (!TextUtils.isEmpty(fc)) {
                    try {
                        jo = new JSONObject(fc);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }
                if (jo != null) {
                    frameCount = jo.optInt("count");
                    if (frameCount > 0) {
                        String format = jo.optString("texture");
                        for (Sprite s : spriteView.sprites) {
                            s.textureType = "png".equals(format) ? Sprite.TextureType.PNG : Sprite.TextureType.ETC1;
                            spriteView.notifyTextureTypeChanged();
                        }
                        frameLoop = jo.optInt("loop") == 1;
                        frameScale = (float)jo.optDouble("scale");
                        frameDuration = jo.optLong("duration");
                        JSONArray ja = jo.optJSONArray("audio");
                        if (ja != null) {
                            audioMap = new HashMap<>();
                            for (int i = 0; i < ja.length(); i++) {
                                JSONObject j = ja.optJSONObject(i);
                                String a = frameFolder + "/" + j.optString("file") + ".mp3";
                                audioMap.put(j.optInt("begin"), createPlayer(a, frameLoop));
                            }
                        }
                        startRender();
                        if (callback != null) {
                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    callback.onStarted();
                                }
                            });
                        }
                    }
                }
            }
        }.start();
    }

    private String[] readFiles(String assetFolder) {
        if (TextUtils.isEmpty(assetFolder)) return null;
        String[] files;
        try {
            if ((files = assetManager.list(assetFolder)) == null) return null;
            return files;
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    private String readStrFromAssetFile(String filePath) {
        try {
            InputStream fin = assetManager.open(filePath);
            String ret = streamToString(fin);
            fin.close();
            return ret;
        } catch (IOException e) {
            return null;
        }
    }

    private String streamToString(InputStream is) throws IOException {
        BufferedReader reader = new BufferedReader(new InputStreamReader(is));
        StringBuilder sb = new StringBuilder();
        String line = null;
        while ((line = reader.readLine()) != null) {
            sb.append(line);
        }
        reader.close();
        return sb.toString();
    }
}
