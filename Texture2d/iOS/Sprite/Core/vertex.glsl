attribute vec4 a_Position;
attribute vec2 a_TexCoordinate;
varying vec2 v_TexCoordinate;
uniform mat4 u_projectionMatrix;
uniform mat4 u_cameraMatrix;
uniform mat4 u_modelMatrix;

void main() {
    gl_Position = u_projectionMatrix * u_cameraMatrix * u_modelMatrix * a_Position;
    v_TexCoordinate = a_TexCoordinate;
}
