precision mediump float;
uniform sampler2D u_Texture;
varying float v_ETC;
varying vec2 v_TextureCoordinate;
varying vec2 v_AlphaCoordinate;

void main() {
    if (v_ETC != 0.0) {
        vec4 color = texture2D(u_Texture, v_TextureCoordinate);
        color.a = texture2D(u_Texture, v_AlphaCoordinate).r;
        gl_FragColor = color;
    } else {
        gl_FragColor = texture2D(u_Texture, v_TextureCoordinate);
    }
}
