attribute vec4 a_Position;
attribute vec2 a_TextureCoordinate;
varying vec2 v_TextureCoordinate;
varying vec2 v_AlphaCoordinate;
uniform mat4 u_projectionMatrix;
uniform mat4 u_cameraMatrix;
uniform mat4 u_modelMatrix;

void main() {
    gl_Position = u_projectionMatrix * u_cameraMatrix * u_modelMatrix * a_Position;
    v_TextureCoordinate = a_TextureCoordinate * vec2(1.0, 0.5);
    v_AlphaCoordinate = v_TextureCoordinate + vec2(0.0, 0.5);
}