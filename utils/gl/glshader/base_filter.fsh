precision highp float;

varying highp vec2 vTextureCoordinate;

uniform sampler2D uInputImageTexture;

void main() {
	gl_FragColor = texture2D(uInputImageTexture, vTextureCoordinate);
}
