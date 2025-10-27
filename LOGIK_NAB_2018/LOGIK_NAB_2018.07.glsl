uniform sampler2D adsk_results_pass6, adsk_results_pass2;
uniform float adsk_result_w, adsk_result_h;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor );

void main()
{
	vec2 uv = gl_FragCoord.xy/resolution.xy;
  vec4 o = texture2D(adsk_results_pass6, uv);
  vec4 b = texture2D(adsk_results_pass2, uv);

	vec4 c = vec4(o.a * vec4(1.0,0.0,0.0, 1.0) + (1.0 - o.a) * b);
	c = adsk_getBlendedValue(29, c, b);

  gl_FragColor= c;
}
