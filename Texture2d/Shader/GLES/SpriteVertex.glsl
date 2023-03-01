attribute vec4 a_Position;
attribute vec2 a_TextureCoordinate;
varying float v_ETC;
varying vec2 v_rgbCoordinate;
varying vec2 v_alphaCoordinate;
uniform mat4 u_projectionMatrix;
uniform mat4 u_cameraMatrix;
uniform mat4 u_modelMatrix;
uniform float u_ETC;

void main() {
    gl_Position = u_projectionMatrix * u_cameraMatrix * u_modelMatrix * a_Position;
    v_ETC = u_ETC;
    if (v_ETC != 0.0) {
        v_rgbCoordinate = a_TextureCoordinate * vec2(1.0, 0.5);
        v_alphaCoordinate = v_rgbCoordinate + vec2(0.0, 0.5);
    } else {
        v_rgbCoordinate = a_TextureCoordinate;
    }
}
