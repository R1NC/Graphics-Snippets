package xyz.rinc.gl.sprite;

import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.graphics.BitmapFactory;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.text.TextUtils;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.concurrent.ConcurrentHashMap;

public class SpritePlayer {

    private static final String TAG = "SpritePlayer";

    private static final String EXTENSION_PNG = ".png";
    private static final String EXTENSION_PKM = ".pkm";

    private String frameFolder;
    private int frameIndex = 0, frameCount;
    private boolean loop;
    private float frameScale = 1.f;
    private long frameDuration;

    private SpriteView spriteView;
    private boolean rendering, paused, destroyed;
    private AssetManager assetManager;

    private Callback callback;

    private ConcurrentHashMap<AudioDuration, MediaPlayer> audioMap;

    public boolean skipFrame;

    private class AudioDuration {
        int begin, end;
    }

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
        audioMap = new ConcurrentHashMap<>();
    }

    public void setCallback(Callback callback) {
        this.callback = callback;
    }

    private void startRender() {
        if (rendering || frameFolder == null || frameCount <= 0 || (!loop && frameIndex > frameCount-1)) return;
        if (paused) {
            if (callback != null)  callback.onResumed();
            paused = false;
        }
        new Thread(()->{
            while (!paused && !destroyed && (loop || frameIndex <= frameCount-1)) {
                long t0 = System.currentTimeMillis();

                if (loop && frameIndex >= frameCount-1 && frameIndex % frameCount == 0) {
                    if (callback != null) {
                        spriteView.post(()->callback.onLooped()));
                    }
                }

                for (AudioDuration ad : audioMap.keySet()) {
                    int target = loop ? frameIndex % frameCount : frameIndex;
                    MediaPlayer player = audioMap.get(ad);
                    if (target >= ad.begin && target <= ad.end) {
                        resumeAudio(player);
                    } else if (target > ad.end) {
                        pauseAudio(player);
                    }
                }

                for (int i = 0; i < spriteView.sprites.size(); i++) {
                    Sprite sprite = spriteView.sprites.get(i);
                    sprite.scale = frameScale;
                    long tx = System.currentTimeMillis();
                    try {
                        if (sprite.textureType == Sprite.TextureType.PNG) {
                            String assetImage = frameFolder + "/" + (frameIndex % frameCount) + EXTENSION_PNG;
                            sprite.png = BitmapFactory.decodeStream(assetManager.open(assetImage));
                            Log.d(TAG, "Load PNG "+assetImage+" cost: "+(System.currentTimeMillis()-tx)+"ms");
                        } else if (sprite.textureType == Sprite.TextureType.ETC1) {
                            String assetImage = frameFolder + "/" + (frameIndex % frameCount) + EXTENSION_PKM;
                            sprite.etc1 = GLUtil.loadTextureETC1(assetManager.open(assetImage));
                            Log.d(TAG, "Load PKM "+assetImage+" cost: "+(System.currentTimeMillis()-tx)+"ms");
                        }
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
                refreshSpriteView();

                long t1 = System.currentTimeMillis();
                if (t1 - t0 < frameDuration) {
                    try {
                        Thread.sleep(frameDuration + t0 - t1);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    frameIndex++;
                } else {
                    frameIndex += skipFrame ? (t1 - t0) / frameDuration : 1;
                }
            }

            rendering = false;
            pauseAllAudios();
            if (!destroyed) {
                spriteView.post(()->{
                    if (paused) {
                        if (callback != null) callback.onPaused();
                    } else {
                        if (callback != null) callback.onStopped();
                        for (int i = 0; i < spriteView.sprites.size(); i++) {
                            spriteView.sprites.get(i).scale = 0;
                        }
                        refreshSpriteView();
                    }
                });
            }
        }).start();
    }

    private void refreshSpriteView() {
        spriteView.post(()->spriteView.requestRender()));
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

    private void resumeAudio(MediaPlayer player) {
        if (player != null) {
            try {
                if (!player.isPlaying() && (player.getDuration() > 0 && player.getCurrentPosition() < player.getDuration())) {
                    player.start();
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private void pauseAudio(MediaPlayer player) {
        if (player != null) {
            try {
                if (player.isPlaying()) {
                    player.pause();
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private void pauseAllAudios() {
        for (MediaPlayer player : audioMap.values()) {
            pauseAudio(player);
        }
    }

    private void releaseAllAudios() {
        for (AudioDuration ad : audioMap.keySet()) {
            MediaPlayer p = audioMap.get(ad);
            if (p != null) {
                p.release();
            }
        }
        audioMap.clear();
    }

    private void releaseSprites(boolean reset) {
        for (Sprite sprite : spriteView.sprites) {
            sprite.release();
        }
        spriteView.sprites.clear();
        if (reset) {
            spriteView.sprites.add(new Sprite(spriteView.getContext()));
        }
        spriteView.notifyDataSetChanged();
    }

    public void onPause() {
        spriteView.onPause();
        pauseAllAudios();
        paused = true;
    }

    public void onResume() {
        spriteView.onResume();
        startRender();
    }

    public void onDestroy() {
        releaseSprites(false);
        pauseAllAudios();
        releaseAllAudios();
        destroyed = true;
    }

    public void play(String assetFolder) {
        if (readFiles(assetFolder) == null) return;

        frameIndex = 0;
        frameCount = 0;
        frameFolder = assetFolder;

        releaseAllAudios();
        releaseSprites(true);

        new Thread(()->{
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
                        loop = jo.optInt("loop") == 1;
                        frameScale = (float)jo.optDouble("scale");
                        frameDuration = jo.optLong("duration");
                        JSONArray ja = jo.optJSONArray("audio");
                        if (ja != null) {
                            if (!audioMap.isEmpty()) audioMap.clear();
                            for (int i = 0; i < ja.length(); i++) {
                                JSONObject j = ja.optJSONObject(i);
                                String a = frameFolder + "/" + j.optString("file") + ".mp3";
                                AudioDuration ad = new AudioDuration();
                                ad.begin = j.optInt("begin");
                                ad.end = j.optInt("end");
                                audioMap.put(ad, createPlayer(a, loop));
                            }
                        }
                        paused = false;
                        startRender();
                        if (callback != null) {
                            spriteView.post(()->callback.onStarted()));
                        }
                    }
                }
        }).start();
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
