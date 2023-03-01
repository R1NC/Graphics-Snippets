precision mediump float;
uniform sampler2D u_Texture;
varying float v_ETC;
varying vec2 v_rgbCoordinate;
varying vec2 v_alphaCoordinate;

void main() {
    if (v_ETC != 0.0) {
        vec4 color = texture2D(u_Texture, v_rgbCoordinate);
        color.a = texture2D(u_Texture, v_alphaCoordinate).r;
        gl_FragColor = color;
    } else {
        gl_FragColor = texture2D(u_Texture, v_rgbCoordinate);
    }
}
