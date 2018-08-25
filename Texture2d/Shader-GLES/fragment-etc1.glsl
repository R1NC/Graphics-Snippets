precision mediump float;
uniform sampler2D u_Texture;
varying vec2 v_TextureCoordinate;
varying vec2 v_AlphaCoordinate;

void main() {
    vec4 color = texture2D(u_Texture, v_TextureCoordinate);
    color.a = texture2D(u_Texture, v_AlphaCoordinate).r;
    gl_FragColor = color;
}