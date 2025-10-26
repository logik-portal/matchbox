uniform float adsk_result_w;
uniform float adsk_result_h;

uniform sampler2D input1;
uniform sampler2D input2;

uniform bool inverseSource;

void main(void)
{
	vec2 st1;
	st1.x = gl_FragCoord.x / adsk_result_w;
	st1.y = gl_FragCoord.y / adsk_result_h;
	
	vec4 getDispInput;
	getDispInput = texture2D(input1, st1);
	

	vec2 stDisp;
	stDisp.x = (getDispInput.x + getDispInput.z);
	stDisp.y = (getDispInput.y + getDispInput.z);
	
	vec4 getDispInput1;
	getDispInput1 = texture2D(input2, stDisp);

	// bools won't autocast to int anymore and casting as (int) seems
	// to confuse the shader compiler in 2025

	int invSrc = inverseSource ? 1 : 0;

	gl_FragColor = getDispInput1 * (1 - invSrc) + ((1 * invSrc) + (-1 * invSrc) * getDispInput1);
}
