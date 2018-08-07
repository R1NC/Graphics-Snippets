package xyz.rinc.gl;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;

import xyz.rinc.gl.sprite.SpritePlayer;
import xyz.rinc.gl.sprite.SpriteView;

public class SpriteActivity extends AppCompatActivity {
    
    private SpritePlayer spritePlayer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.activity_sprite);

        SpriteView spriteView = findViewById(R.id.glssv);
        spritePlayer = new SpritePlayer(spriteView);
        spritePlayer.setCallback(new SpritePlayer.Callback() {
            @Override
            public void onStarted() {
                Log.d("@_@", "onStarted");
            }

            @Override
            public void onPaused() {
                Log.d("@_@", "onPaused");
            }

            @Override
            public void onResumed() {
                Log.d("@_@", "onResumed");
            }

            @Override
            public void onStopped() {
                Log.d("@_@", "onStopped");
            }

            @Override
            public void onLooped() {
                Log.d("@_@", "onLooped");
            }
        });
    }

    @Override
    public void onResume() {
        super.onResume();
        spritePlayer.onResume();
    }

    @Override
    public void onPause() {
        super.onPause();
        spritePlayer.onPause();
    }
    
    @Override
    public void onDestroy() {
        spritePlayer.onDestroy();
        super.onDestroy();
    }

    public void onClickBtn(View v) {
        spritePlayer.setParameters("love", 2.f, 1, false);
    }
}
