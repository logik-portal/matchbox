#version 120
// based on https://www.shadertoy.com/view/MtcSzH by ttoinou
uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

void main()
{
	vec2 uv = gl_FragCoord.xy / res;
	vec3 c = texture2D(front, uv).rgb;
  gl_FragColor = vec4(c, 1.0);
}
