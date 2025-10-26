#version 120
// creating colour noise for grain
vec2 center = vec2(.5);
uniform float adsk_time, adsk_result_w, adsk_result_h;
uniform vec3 c_noise;
uniform float sat;

vec2 res = vec2(adsk_result_w, adsk_result_h);
float time = adsk_time *.05;

uniform float overall;

float rand2(vec2 co)
{
	return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

// Algorithm from Chapter 16 of OpenGL Shading Language
vec3 saturation(vec3 rgb, float adjustment)
{
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}

vec3 noise(vec2 uv)
{
	vec2 c = res.x*vec2(1.,(res.y/res.x));
	vec3 col = vec3(0.0);

   	float r = rand2(vec2((2.+time) * floor(uv.x*c.x)/c.x, (2.+time) * floor(uv.y*c.y)/c.y));
   	float g = rand2(vec2((5.+time) * floor(uv.x*c.x)/c.x, (5.+time) * floor(uv.y*c.y)/c.y));
   	float b = rand2(vec2((9.+time) * floor(uv.x*c.x)/c.x, (9.+time) * floor(uv.y*c.y)/c.y));

	col = vec3(r,g,b);

	return col;
}


void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec3 grain = noise(uv);
	vec3 grau = vec3 (0.5);
	vec3 c = vec3(0.0);

	grain.r = mix(grau.r, grain.r, c_noise.r * .05 * overall);
	grain.g = mix(grau.g, grain.g, c_noise.g * .05 * overall);
	grain.b = mix(grau.b, grain.b, c_noise.b * .05 * overall);

	grain = saturation(grain, sat);

	gl_FragColor = vec4(grain, 1.0);
}
