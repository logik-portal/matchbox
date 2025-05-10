//*****************************************************************************/
// 
// Filename: fur_3vis.glsl
// Author: Eric Pouliot
//
// Copyright (c) 2013 3vis, Inc.
//*****************************************************************************/

uniform sampler2D iChannel0, iChannel1;
uniform float adsk_result_w, adsk_result_h;
uniform float rotation_x, rotation_y, direction_x, direction_y;

// fur ball
// (c) simon green 2013
// @simesgreen
// v1.1

/* Original variables
const float uvScale = 1.0;
const float colorUvScale = 0.1;
const float furDepth = 0.2;
const int furLayers = 64;
const float rayStep = furDepth*2.0 / float(furLayers);
const float furThreshold = 0.4;
const float shininess = 50.0;
*/

uniform float uvScale;
uniform float colorUvScale;
uniform float furDepth;
uniform int furLayers;

uniform float furThreshold;
uniform float shininess;

uniform vec3 centre; // (0.0, 0.0, 2.5)
uniform vec3 L; // (0.0, 1.0, 0.0)

float rayStep = furDepth*2.0 / float(furLayers);

bool intersectSphere(vec3 ro, vec3 rd, float r, out float t)
{
	float b = dot(-ro, rd);
	float det = b*b - dot(ro, ro) + r*r;
	if (det < 0.0) return false;
	det = sqrt(det);
	t = b - det;
	return t > 0.0;
}

vec3 rotateX(vec3 p, float a)
{
    float sa = sin(a);
    float ca = cos(a);
    return vec3(p.x, ca*p.y - sa*p.z, sa*p.y + ca*p.z);
}

vec3 rotateY(vec3 p, float a)
{
    float sa = sin(a);
    float ca = cos(a);
    return vec3(ca*p.x + sa*p.z, p.y, -sa*p.x + ca*p.z);
}

vec2 cartesianToSpherical(vec3 p)
{		
	float r = length(p);

	float t = (r - (1.0 - furDepth)) / furDepth;	
	p = rotateX(p.zyx, -cos(direction_x*1.5)*t*t*0.4).zyx;	// curl

	p /= r;	
	vec2 uv = vec2(atan(p.y, p.x), acos(p.z));

	uv.y -= t*t*(0.1*direction_y);	// curl down
	return uv;
}

// returns fur density at given position
float furDensity(vec3 pos, out vec2 uv)
{
	uv = cartesianToSpherical(pos.xzy);	
	vec4 tex = texture2D(iChannel0, uv*uvScale);

	// thin out hair
	float density = smoothstep(furThreshold, 1.0, tex.x);
	
	float r = length(pos);
	float t = (r - (1.0 - furDepth)) / furDepth;
	
	// fade out along length
	float len = tex.y;
	density *= smoothstep(len, len-0.2, t);

	return density;	
}

// calculate normal from density
vec3 furNormal(vec3 pos, float density)
{
    float eps = 0.01;
    vec3 n;
	vec2 uv;
    n.x = furDensity( vec3(pos.x+eps, pos.y, pos.z), uv ) - density;
    n.y = furDensity( vec3(pos.x, pos.y+eps, pos.z), uv ) - density;
    n.z = furDensity( vec3(pos.x, pos.y, pos.z+eps), uv ) - density;
    return normalize(n);
}

vec3 furShade(vec3 pos, vec2 uv, vec3 ro, float density)
{
	// lighting
//	const vec3 L = vec3(0, 1, 0);
	vec3 V = normalize(ro - pos);
	vec3 H = normalize(V + L);

	vec3 N = -furNormal(pos, density);
	//float diff = max(0.0, dot(N, L));
	float diff = max(0.0, dot(N, L)*0.5+0.5);
	float spec = pow(max(0.0, dot(N, H)), shininess);
	
	// base color
	vec3 color = texture2D(iChannel1, uv*colorUvScale).xyz;

	// darken with depth
	float r = length(pos);
	float t = (r - (1.0 - furDepth)) / furDepth;
	t = clamp(t, 0.0, 1.0);
	float i = t*0.5+0.5;
		
	return color*diff*i + vec3(spec*i);
}		

vec4 scene(vec3 ro,vec3 rd)
{
	vec3 p = vec3(0.0);
	const float r = 1.0;
	float t;				  
	bool hit = intersectSphere(ro - p, rd, r, t);
	
	vec4 c = vec4(0.0);
	if (hit) {
		vec3 pos = ro + rd*t;

		// ray-march into volume
		for(int i=0; i<furLayers; i++) {
			vec4 sampleCol;
			vec2 uv;
			sampleCol.a = furDensity(pos, uv);
			if (sampleCol.a > 0.0) {
				sampleCol.rgb = furShade(pos, uv, ro, sampleCol.a);

				// pre-multiply alpha
				sampleCol.rgb *= sampleCol.a;
				c = c + sampleCol*(1.0 - c.a);
				//if (c.a > 0.95) break;
			}
			
			pos += rd*rayStep;
		}
	}
	
	return c;
}

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h );
	uv = uv*2.0-1.0;
	uv.x *= adsk_result_w / adsk_result_h;
	
	vec3 ro = centre;
	vec3 rd = normalize(vec3(uv, -2.0));
		
    	ro = rotateX(ro, rotation_x);	
    	ro = rotateY(ro, rotation_y);	
    	rd = rotateX(rd, rotation_x);
    	rd = rotateY(rd, rotation_y);
	
	gl_FragColor = scene(ro, rd);
}
