#version 120

uniform vec2 mouse;
uniform bool antialiasing;
uniform float aaSteps;

uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);


float time = adsk_time *.05;
	
#define PI 3.1415926535

struct Ray {
	vec3 pos;
	vec3 dir;
};
	
float udRoundBox( vec3 p, vec3 b, float r )
{
	return length(max(abs(p)-b,0.0))-r;
}

vec3 repPos( vec3 p, vec3 c )
{
    return mod(p,c)-0.5*c;
}


float subFunc(vec3 pos)
{
	float a = mod(atan(pos.y, pos.x), PI / 1.5) - PI / 1.5 / 2.0;
	float xyLen = length(pos.xy);
	a -= pos.z;
	pos.xy = vec2(xyLen * sin(a), xyLen * cos(a));
	pos = repPos(pos, vec3(0.03));
	return udRoundBox(pos, vec3(0.0138), 0.001);
}

float func(vec3 pos)
{
	float a = mod(atan(pos.y, pos.x), PI / 1.5) - PI / 1.5 / 2.0;
	float xyLen = length(pos.xy);
	a += pos.z;
	pos.xy = vec2(xyLen * sin(a), xyLen * cos(a));
	pos = repPos(pos, vec3(0.33));
	return udRoundBox(pos, vec3(0.1), 0.01);
}

float distFunc(vec3 pos)
{
	
	return max(-subFunc(pos), func(pos));
	//return subFunc(pos);
}

vec3 getNormal(vec3 pos)
{
	const float d = 0.0001;
	return normalize(
		vec3(
			distFunc(pos + vec3(d, 0, 0)) - distFunc(pos - vec3(d, 0, 0)),
			distFunc(pos + vec3(0, d, 0)) - distFunc(pos - vec3(0, d, 0)),
			distFunc(pos + vec3(0, 0, d)) - distFunc(pos - vec3(0, 0, d))
		)
	);
}

vec3 rayMarching(vec2 pos) {
	vec3 cameraPos = vec3(0.0, 0.0, -10.0 + time * 0.2);
	Ray ray;
	ray.pos = cameraPos;
	ray.dir = normalize(vec3(pos * 2.0, 1.0));
	float d;
	for(int i = 0; i < 64; ++i)
	{
		d = distFunc(ray.pos);
		ray.pos += d * ray.dir;
		if (abs(d) < 0.001) break;
	}
	
	float light = (dot(getNormal(ray.pos), vec3(1, 1, -1)));
	return clamp(vec3(0.3, 0.8, 1.0) * light + (ray.pos - cameraPos).z * 0.5, 0.0, 1.0);
}

float rand(vec2 p) {
	return fract(sin(dot(p ,vec2(12.9898,78.233))) * 43758.5453);
}

void main( void ) 
{
	vec3 col = vec3(0.0);
	vec2 pos1 = (gl_FragCoord.xy + vec2(0.0, 0.0) - resolution * 0.5)  / resolution.y + sin(time*.1) * 0.5;

	if ( antialiasing )
	{
		for(int i=0; i<aaSteps; i++)
		{
			float aa_offset = rand(vec2(i, i));
			col += vec3(rayMarching(pos1 + aa_offset * 0.001));
		}
		col /= float(aaSteps);
	}
	else
		col = vec3(rayMarching(pos1));
	gl_FragColor.rgb = col;
}