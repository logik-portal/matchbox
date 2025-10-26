//based on https://www.shadertoy.com/view/XscXRl by FabriceNeyret2
// here, prepare your source image

uniform sampler2D front, matte;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

void main()
{
	vec2 uv = gl_FragCoord.xy / res;
	vec3 c = texture2D(front, uv).rgb;
	float m = texture2D(matte, uv).a;
  gl_FragColor = vec4(c,m);
}
