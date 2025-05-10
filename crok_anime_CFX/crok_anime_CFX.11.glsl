#version 120
// based on https://www.shadertoy.com/view/4dVGRW by hughsk

// load blurred normals
uniform sampler2D adsk_results_pass4;

// load source
uniform sampler2D adsk_results_pass10;

uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform vec3 pole;
uniform vec3 lightDir;
uniform float Shades, lightint;

float detail = 1.0;

vec2 getDeltas(sampler2D buffer, vec2 uv)
{
  vec2 pixel = vec2(1. / res.xy);
  float dpos = 0.0;
  float dnor = 0.0;

  vec4 s0 = texture2D(adsk_results_pass4, uv + pixel.xy * pole.xx); // x1, y1
  vec4 s1 = texture2D(adsk_results_pass4, uv + pixel.xy * pole.yx); // x2, y1
  vec4 s2 = texture2D(adsk_results_pass4, uv + pixel.xy * pole.zx); // x3, y1
  vec4 s3 = texture2D(adsk_results_pass4, uv + pixel.xy * pole.xy); // x1, y2
  vec4 s4 = texture2D(adsk_results_pass4, uv + pixel.xy * pole.yy); // x2, y2
  vec4 s5 = texture2D(adsk_results_pass4, uv + pixel.xy * pole.zy); // x3, y2
  vec4 s6 = texture2D(adsk_results_pass4, uv + pixel.xy * pole.xz); // x1, y3
  vec4 s7 = texture2D(adsk_results_pass4, uv + pixel.xy * pole.yz); // x2, y3
  vec4 s8 = texture2D(adsk_results_pass4, uv + pixel.xy * pole.zz); // x3, y3

  dpos = (
    abs(s1.a - s7.a) +
    abs(s5.a - s3.a) +
    abs(s0.a - s8.a) +
    abs(s2.a - s6.a)
  ) * 0.5;
  dpos += (
    max(0.0, 1.0 - dot(s1.rgb, s7.rgb)) +
    max(0.0, 1.0 - dot(s5.rgb, s3.rgb)) +
    max(0.0, 1.0 - dot(s0.rgb, s8.rgb)) +
    max(0.0, 1.0 - dot(s2.rgb, s6.rgb))
  );

  dpos = pow(max(dpos - 0.5, 0.0), 5.0 * detail);

  return vec2(dpos, dnor);
}

void main( void )
{
    vec2 uv = gl_FragCoord.xy / res.xy;
    vec4 buf = texture2D(adsk_results_pass4, uv);
    vec3 col = texture2D(adsk_results_pass10, uv).rgb;
    vec3 nor = buf.rgb;

	// flat shading
	float intensity = dot(lightDir*vec3(0.01),normalize(nor)) * lightint;
	col *= ceil(intensity * Shades)/ Shades;

    vec2 deltas = getDeltas(adsk_results_pass4, uv);
    col -= (deltas.x - deltas.y);
    gl_FragColor = vec4(col, 1.0);
}
