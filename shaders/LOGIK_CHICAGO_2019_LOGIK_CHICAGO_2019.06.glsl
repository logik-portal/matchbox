#version 120
// grain 1/4

uniform float adsk_time, adsk_result_w, adsk_result_h;
float time = adsk_time *.05;

float overall = 4.0;
vec3 amount = vec3(1.0);

vec3 noise(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
  p3 += dot(p3, p3.yxz+19.19);
  return fract((p3.xxy + p3.yxx)*p3.zyx);
}

void main(void)
{
	vec2 position = gl_FragCoord.xy;
	vec3 pos = vec3(position, time*.3) + time * 500. + 50.0;

	vec3 grain = noise(pos);
	vec3 grau = vec3 (0.5);
	vec3 c = vec3(0.0);

	grain = mix(grau, grain, overall * .1);
	grain = vec3(grain.r);

	gl_FragColor = vec4(grain, 1.0);
}
