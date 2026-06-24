uniform sampler2D adsk_results_pass1, adsk_results_pass3;
uniform float adsk_result_w, adsk_result_h;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);

void main()
{
	vec2 uv = gl_FragCoord.xy/resolution.xy;
  vec4 o = texture2D(adsk_results_pass1, uv);
  vec4 b = texture2D(adsk_results_pass3, uv);
	vec3 c = vec3(0.0);
	if ( o.rgb != vec3(0.0) )
	  c = vec3(o.a * o.rgb + (1.0 - o.a) * b.rgb);
		else
		c = b.rgb;

  gl_FragColor=vec4( c, 1.0 );
}
