#version 120

uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform sampler2D source;
uniform sampler2D adsk_next_frame_source;
//uniform sampler2D adsk_previous_frame_source;
uniform float gain;

vec3 difference( vec3 s, vec3 d )
{
	return abs(d - s);
}

void main()
{
	vec2 uv = gl_FragCoord.xy / res.xy;
	vec3 scr = texture2D(source, uv).rgb;
  vec3 next = texture2D(adsk_next_frame_source, uv).rgb;
  //vec3 prev = texture2D(adsk_previous_frame_source, uv).rgb;
  vec3 col = vec3(0.0);
/*
  if (col == vec3(0.0))
    col = difference(scr, prev);
  else */

  col = difference(scr, next);
	col = vec3(max(max(col.r, col.g), col.b));
	col = col * gain;

  // clamp the matte output
	col = clamp(col, 0.0, 1.0);

  gl_FragColor = vec4(scr, col.r);
}
