//based on https://www.shadertoy.com/view/XscXRl by FabriceNeyret2
// here, prepare your source image

uniform sampler2D adsk_results_pass1, adsk_results_pass3;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform float blend;

void main()
{
	vec2 uv = gl_FragCoord.xy / res;
	vec3 f = texture2D(adsk_results_pass1, uv).rgb;
	//float m = texture2D(adsk_results_pass1, uv).a;
	vec3 r = texture2D(adsk_results_pass3, uv).rgb;

	vec3 c = mix(f, r, blend);

  gl_FragColor = vec4(c, 1.0);
}
