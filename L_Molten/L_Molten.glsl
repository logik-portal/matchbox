//textured noise for Matchbox based on https://www.shadertoy.com/view/Mss3zn

uniform float adsk_time;
uniform float speed;
vec2 resolution;
uniform float adsk_result_w, adsk_result_h;
const float gamma = 2.2;

uniform vec3 color;
uniform float offset;

const int iters = 1024;

const float origin_z = 0.0;
const float plane_z = 4.0;
const float far_z = 64.0;

const float step = (far_z - plane_z) / float(iters) * 0.025;

const float color_bound = 0.0;
const float upper_bound = 1.0;

uniform float scale;

uniform float disp;

float calc_this(vec3 p, float disx, float disy, float disz)
{
	float c = sin(sin((p.x + disx) * sin(sin(p.z + disz)) + (adsk_time*speed)) + sin((p.y + disy) * cos(p.z + disz) + 2.0 * (adsk_time*speed)) + sin(3.0*p.z + disz + 3.5 * (adsk_time*speed)) + sin((p.x + disx) + sin(p.y + disy + 2.5 * (p.z + disz - (adsk_time*speed)) + 1.75 * (adsk_time*speed)) - 0.5 * (adsk_time*speed)) + offset );
	return c;
}

vec3 get_intersection()
{
	vec2 position = (gl_FragCoord.xy / resolution.xy - 0.5) * scale;

	vec3 pos = vec3(position.x, position.y, plane_z);
	vec3 origin = vec3(0.0, 0.0, origin_z);

	vec3 dir = pos - origin;
	vec3 dirstep = normalize(dir) * step;

	dir = normalize(dir) * plane_z;


	float c;

	for (int i=0; i<iters; i++)
	{
		c = calc_this(dir, 0.0, 0.0, 0.0);

		if (c > color_bound)
		{
			break;
		}

		dir = dir + dirstep;
	}

	return dir;
}


void main()
{
	resolution = vec2(adsk_result_w, adsk_result_h);
	
	vec3 p = get_intersection();
	float dx = color_bound - calc_this(p, disp, 0.0, 0.0);
	float dy = color_bound - calc_this(p, 0.0, disp, 0.0);

	vec3 du = vec3(disp, 0.0, dx);
	vec3 dv = vec3(0.0, disp, dy);
	vec3 normal = normalize(cross(du, dv));

	vec3 light = normalize(vec3(0.0, 0.0, 1.0));
	float l = dot(normal, light);

	float cc = pow(l, gamma);
	gl_FragColor = vec4(cc*color.r, cc*color.g, cc*color.b, 1.0);
}