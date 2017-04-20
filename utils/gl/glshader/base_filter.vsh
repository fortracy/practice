attribute vec4 aPosition;
attribute vec4 aInputTextureCoordinate;

varying vec2 vTextureCoordinate;

uniform mat4 uModelViewProjMatrix;

void main() {
    gl_Position = uModelViewProjMatrix * aPosition;
	vTextureCoordinate = aInputTextureCoordinate.xy;
}
