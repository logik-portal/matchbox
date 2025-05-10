uniform float adsk_time;
uniform float adsk_result_w, adsk_result_h;
uniform float Speed;
uniform float Offset;
uniform float Zoom;
uniform float Detail, Noise;
uniform float brightness;
uniform float contrast;
uniform float saturation;
uniform float tint;
uniform bool clamp_g;
uniform vec3 co0, co1, co2, co3, co4;
uniform vec3 tint_col;
uniform vec2 Aspect;

vec2 resolution = vec2(adsk_result_w, adsk_result_h);
float time = adsk_time *.02 * Speed + Offset;

const vec3 LumCoeff = vec3(0.2125, 0.7154, 0.0721);

uniform int VolumeSteps; // 32
uniform float StepSize; // 0.25
uniform float Density; // 0.2
uniform float NoiseFreq; // 2.0
uniform float NoiseAmp; // 2.0
uniform vec3 NoiseAnim; // vec3(0, 0, 0)

mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
/*
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}
*/
// From https://www.shadertoy.com/view/4djSRW
float hash( float p )
{
	vec2 p2 = fract(vec2(p) * .1031);
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
    float f;
    f = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p ); p = m*p*2.01;
    f += 0.0625*noise( p );
    return f;
}

float distanceFunc(vec3 p)
{
	float d = length(p);	// distance to sphere
	d += fbm(p*NoiseFreq + NoiseAnim*time) * NoiseAmp;
	return d;
}

vec4 gradient(float x)
{
	x=sin(x-time);

	vec4 c0 = vec4(co0, 0.1);	// yellow
	vec4 c1 = vec4(co1, 0.9);	// red
	vec4 c2 = vec4(co2, 0); 	// black
	vec4 c3 = vec4(co3, 0.2); 	// blue
	vec4 c4 = vec4(co4, 0); 	// black

	x = clamp(x, 0.0, 0.999);
	float t = fract(x*4.0);
	vec4 c;
	if (x < 0.25) {
		c =  mix(c0, c1, t);
	} else if (x < 0.5) {
		c = mix(c1, c2, t);
	} else if (x < 0.75) {
		c = mix(c2, c3, t);
	} else {
		c = mix(c3, c4, t);
	}
	return c;
}

vec4 shade(float d)
{
	vec4 c = gradient(d);
	return c;
}


vec4 volumeFunc(vec3 p)
{
	float d = distanceFunc(p);
	return shade(d);
}

vec4 rayMarch(vec3 rayOrigin, vec3 rayStep, out vec3 pos)
{
	vec4 sum = vec4(0, 0, 0, 0);
	pos = rayOrigin;
	for(int i=0; i<VolumeSteps; i++) {
		vec4 col = volumeFunc(pos);
		col.a *= Density;
		col.rgb *= col.a;
		sum = sum + col*(1.0 - sum.a);
		pos += rayStep;
	}
	return sum;
}

void main(void)
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= resolution.x/resolution.y;

    float rotx = 0.0;
    float roty = 0.0;

    vec3 ro = Detail * normalize(vec3(cos(roty), cos(rotx), sin(roty)));
    vec3 ww = normalize(vec3(0.0,0.0,0.0) - ro);
    vec3 uu = Aspect.x * normalize(cross( vec3(0.0,1.0,0.0), ww ));
    vec3 vv = Aspect.y * normalize(cross(ww,uu));
    vec3 rd = normalize( p.x*uu + p.y*vv + ww * Zoom );

    ro += rd * Noise;

    vec3 hitPos;
    vec4 col = rayMarch(ro, rd*StepSize, hitPos);
    vec3 avg_lum = vec3(0.5, 0.5, 0.5);
    vec3 intensity = vec3(dot(col.rgb, LumCoeff));

    vec3 sat_color = mix(intensity, col.rgb, saturation);
    vec3 con_color = mix(avg_lum, sat_color, contrast);
	vec3 brt_color = con_color - 1.0 + brightness;
	vec3 fin_color = mix(brt_color, brt_color * tint_col, tint);

	if ( clamp_g )
		fin_color = clamp(fin_color, 0.0, 1.0);
    gl_FragColor = vec4(fin_color, 1.0);
	}
