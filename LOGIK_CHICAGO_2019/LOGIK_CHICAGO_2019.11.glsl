uniform sampler2D adsk_results_pass10;
uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);

float radius = 1.12;
float softness = 0.57;
float blend = 1.0;
vec3 v_color = vec3(1.0);
vec2 center = vec2(0.5, 0.5);
float iGlobalTime = adsk_time*.05;

void main( void )
{
  vec2 uv = gl_FragCoord.xy / resolution.xy;
	vec2 center = (2.0 * ((gl_FragCoord.xy / resolution.xy) - 0.25) - center);
	vec3 original = texture2D(adsk_results_pass10, uv).rgb;
	vec3 tint_col = v_color * original;
  float length = length(center);
  float vig = smoothstep(radius, radius-softness, length);
	vec3 matte = vec3(1.0-vig);
	vec3 fin_col = mix(original, tint_col, blend);
	fin_col = matte * fin_col + (1.0 - matte) * original;
	fin_col = tint_col * original;
	fin_col = matte * fin_col + (1.0 - matte) * original;
	fin_col = mix(original, fin_col, blend);


  float blend_anim2 = smoothstep(0., 25., iGlobalTime - .25);
  float closing = smoothstep(60., 0., iGlobalTime - 326.);
  // add letterbox
  float offset = 0.0;
  fin_col *= step(abs(uv.y - 0.5 + offset), blend_anim2 * .5);
  fin_col *= step(abs(uv.y - 0.5 + offset), closing * .5);


	gl_FragColor = vec4(fin_col, vig);
}
