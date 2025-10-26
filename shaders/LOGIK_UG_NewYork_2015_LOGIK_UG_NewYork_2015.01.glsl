// based on https://www.shadertoy.com/view/XdjGW3
// srtuss, 2014
// named after an amazing freeform(-hardcore) track:
// https://soundcloud.com/finrg-recordings/alek-szahala-pink-magic

uniform int detail;
uniform bool enable_girl_power;


uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);
float time = adsk_time *.05;


vec2 rotate(vec2 p, float a)
{
	return vec2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));
}
// fast iq 3D Noise
float hash( float n ) { return fract(sin(n)*753.5453123); }
float n3d( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
	
    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                   mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}

float fbm(vec3 p, float x)
{
	vec3 pp = p;
	float t = time;
	float ll = dot(p, p);
	p /= ll;
	p = p * (1.0 + ll * x + ll * ll * 0.01);
	float v = time * 0.2;
	return (n3d( p + v * vec3( 0.0,  0.0, 1.0)) * 0.5 +
		   n3d((p + v * vec3(-1.0,  0.0, 0.0)) * 2.0 + 5.0) * 0.25 +
		   n3d((p + v * vec3( 0.0, -1.0, 0.0)) * 4.0 - 5.0) * 0.125 +
		   n3d((p + v * vec3( 0.0,  1.0, 0.0)) * 8.0 + 5.0) * 0.0625) * exp(ll * -0.03);
}
float density(vec3 p, float x)
{
	return pow(1.0 - abs(fbm(p, x) * 2.0 - 1.0), 32.0);
}

void main()
{
	vec2 uv = gl_FragCoord.xy / resolution;
	uv = 2.0 * uv - 1.0;
	uv.x *= resolution.x / resolution.y;
	vec3 col = vec3(0.0);
	vec3 ro = vec3( -0.5, 0.5, -0.9);
	vec3 rd = normalize(vec3(uv, 1.4));
	ro.xz = rotate(ro.xz, time * 0.2);
	rd.xz = rotate(rd.xz, time * 0.2);
	rd.xy = rotate(rd.xy, sin(time * 0.2) * 0.2);
	float a = 0.0;
	vec3 r = ro + rd * 0.01;
	float x = sin(time * 0.2) * 0.3 + 0.4;
	for(int i = 0; i < detail + 2; i ++)
	{
		a += density(r, x);
		r += rd * 2.0 / float(detail + 2 );
	}	
	float v = a * 2.0 / float(detail + 2);
	
	if ( enable_girl_power )
		col = pow(vec3(v), vec3(0.6, 1.0, 0.7) * 5.0) * 60.0;
	else
		col = pow(vec3(v), vec3(0.68, 0.6, 0.53) * 9.0) * 60.0;
	col = pow(col, vec3(1.0 / 15.2));
	col = clamp(col, 0.0, 1.0);
	
	gl_FragColor = vec4(col * 1.7 - 0.7, 1.0);
}