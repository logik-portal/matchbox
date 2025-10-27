// Created by Martijn Steinrucken - 2015
// License CC Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// 
// based on https://www.shadertoy.com/view/4lXXDB

vec3 adsk_getVertexPosition();
vec3 adsk_getCameraPosition();
vec3 adsk_getLightPosition();
vec3 adsk_getLightDirection();
vec3 adsk_getLightTangent();
vec3 adsk_getLightColour();
mat4 adsk_getModelViewMatrix();
mat4 adsk_getModelViewInverseMatrix();
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor ); 
vec3 adsk_hsv2rgb( vec3 hsv );
vec3 adsk_getDiffuseMapCoord();
vec4 adsk_getDiffuseMapValue(in vec2 texCoord);

vec3 adsk_getDiffuseMapCoord();
vec4 adsk_getDiffuseMapValue(in vec2 texCoord);


float adsk_getTime();
const float adskUID_twopi = 6.283185307179586;
#define adskUID_luma(col) dot(col, vec3(0.3086, 0.6094, 0.0820))

vec2 adskUID_resolution = vec2(1920., 1080.);

uniform float adskUID_Speed;
uniform float adskUID_Offset;

float adskUID_time = adsk_getTime() * 0.005 * adskUID_Speed + adskUID_Offset;

uniform float adskUID_NUM_LIGHTS; // = 500.;			// number of twinkly lights 
uniform float adskUID__FocalDistance; // = 3.;	// focal distance of the camera
uniform float adskUID__DOF; // = 2.;				// depth of field. How quickly lights go out of focus
uniform float adskUID__ZOOM; // = 0.8;		// camera zoom, smaller values means wider FOV
uniform float adskUID_flicker_speed;
uniform float adskUID_motion_speed;
uniform float adskUID_amplitude;
uniform vec3 adskUID_colourWheel1;
uniform vec3 adskUID_colourWheel2;
uniform int adskUID_blendModes;
uniform float adskUID_height;
uniform bool adskUID_noise_type;


struct adskUID_ray {
    vec3 o;
    vec3 d;
};
adskUID_ray adskUID_e;				// the eye ray


// We are using this function to map the Hue and Gain of the Colour Wheel in HSV to an RGB value
vec3 adskUID_getRGB( float hue )
{
	return adsk_hsv2rgb( vec3( hue, 1.0, 1.0 ) );
}

vec3 adskUID_adjust_saturation(vec3 col, float c)
{
    float l = adskUID_luma(col);
    col = (1.0 - c) * l + c * col;
    return col;
}

// Helper functions - Borrowed from other peoples shaders =================================
vec2 adskUID_hash3(float n) {
	vec2 n2 = vec2(n, -n+2.1323);
    return fract(sin(n2)*1751.5453);
}

float adskUID_cubicPulse( float c, float w, float x )
{
    x = abs(x - c);
    if( x>w ) return 0.;
    x /= w;
    return 1. - x*x*(3.-2.*x);
}

vec3 adskUID_ClosestPoint(adskUID_ray r, vec3 p) {
    // returns the closest point on ray r to point p
    return r.o + max(0., dot(p-r.o, r.d))*r.d;
}

float adskUID_Bokeh(adskUID_ray r, vec3 p) {
	float dist = length( p-adskUID_ClosestPoint(r, p) );
    float distFromCam = length(p-adskUID_e.o);
    float focus = adskUID_cubicPulse(adskUID__FocalDistance, adskUID__DOF, distFromCam);
    vec3 inFocus = vec3(0.05 * adskUID_height, -0.1, 1.);	// outer radius = 0.05, inner radius=0 brightness =1
    vec3 outFocus = vec3(0.25 * adskUID_height, 0.2, .05);	// out of focus is larger, has sharper edge, is less bright
    vec3 thisFocus = mix(outFocus, inFocus, focus);
    return smoothstep(thisFocus.x, thisFocus.y, dist)*thisFocus.z;
}


// Using Ashima's simplex noise
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
 
vec3 adskUID_mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}
 
vec2 adskUID_mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}
 
vec3 adskUID_permute(vec3 x) {
  return adskUID_mod289(((x*34.0)+1.0)*x);
}
 
float adskUID_snoise(vec2 v)
{
  const vec4 C = vec4(0.211324865405187,
                      0.366025403784439,
                     -0.577350269189626,
                      0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
 
  vec2 i1;

  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
 
  i = adskUID_mod289(i);
  vec3 p = adskUID_permute( adskUID_permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));
 
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
 
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
 
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
 
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

// simple value noise
float adskUID_hash( float n ) 
{ 
	return fract(sin(n)*753.5453123); 
}

float adskUID_vnoise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
	
    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix( adskUID_hash(n+  0.0), adskUID_hash(n+  1.0),f.x),
                   mix( adskUID_hash(n+157.0), adskUID_hash(n+158.0),f.x),f.y),
               mix(mix( adskUID_hash(n+113.0), adskUID_hash(n+114.0),f.x),
                   mix( adskUID_hash(n+270.0), adskUID_hash(n+271.0),f.x),f.y),f.z);
}

vec3 adskUID_hash33(vec3 p)
{ 
    float n = sin(dot(p, vec3(7, 157, 113)));    
    return fract(vec3(2097152, 262144, 32768)*n); 
}


vec4 adskUID_Lights(adskUID_ray r, float flicker_s, float motion_s ) 
{
	vec4 adskUID_color1 = vec4(adskUID_getRGB( adskUID_colourWheel1.x / 360.0 ) * vec3( adskUID_colourWheel1.y * 0.01), adskUID_colourWheel1.z * 0.01);
	vec4 adskUID_color2 = vec4(adskUID_getRGB( adskUID_colourWheel2.x / 360.0 ) * vec3( adskUID_colourWheel2.y * 0.01), adskUID_colourWheel2.z * 0.01);
	adskUID_color1.rgb = adskUID_adjust_saturation(adskUID_color1.rgb, adskUID_colourWheel1.z * 0.01);
	adskUID_color2.rgb = adskUID_adjust_saturation(adskUID_color2.rgb, adskUID_colourWheel2.z * 0.01);
	
    vec4 col = vec4(0.);
    float height = 4.;
   	float halfHeight = height/2.;
   
    for(float i=0.; i<adskUID_NUM_LIGHTS; i++) 
	{
    	float c = i/adskUID_NUM_LIGHTS;
        c *= adskUID_twopi;
        vec2 xy = adskUID_hash3(i)*10.-5.;
        float y = fract(c)*height-halfHeight;
		vec3 pos = vec3(xy.x, y, xy.y);
		
		if ( adskUID_noise_type)
		{
			//pos.x += adskUID_vnoise(i * pos * adskUID_time * 0.025 * adskUID_amplitude +568.);
			//pos.y += adskUID_vnoise(i * pos * adskUID_time * 0.015 * adskUID_amplitude + 234.);
			pos += vec3(adskUID_vnoise(i * pos * adskUID_time * 0.03 * adskUID_amplitude + 101.), adskUID_vnoise(i * pos * adskUID_time * 0.02 * adskUID_amplitude + 305.), 0.0);
		}
		else
		{
			pos.x += adskUID_snoise(vec2(i * adskUID_time * 0.0075 * adskUID_amplitude +356., i));
			pos.y += adskUID_snoise(vec2(i * adskUID_time * 0.005 * adskUID_amplitude + 501., i));
			//pos.z += adskUID_snoise(vec2(i * adskUID_time * 0.011, i * adskUID_time *0.003));
		}
		float glitter = 1. +clamp((sin(c+flicker_s*3.)-0.9)*50., 0., 100.);
		col.rgb += adskUID_Bokeh(r, pos)*glitter * mix(vec3(adskUID_color1.rgb), vec3(adskUID_color2.rgb), 0.5+0.5*sin(float(i)*1.2+1.9));
    }
    return col;
}

vec4 adskUID_lightbox(vec4 source)
{
	vec3 uv = adsk_getDiffuseMapCoord();
    vec3 camera = adsk_getCameraPosition();
    vec3 vertex = adsk_getVertexPosition();
    vec3 light = adsk_getLightPosition();
    vec3 lightdir = adsk_getLightDirection();
    vec3 lighttan = adsk_getLightTangent();
    vec3 lightbitan = cross(lightdir, lighttan);
    mat3 lightbasis = mat3(lighttan, -lightbitan, lightdir);
    vec3 dir = normalize(vertex - camera);
    vec3 ro = camera  - light;
    ro *= lightbasis;
	ro /= adskUID__ZOOM;
	vec3 rd = dir * lightbasis;
    ro += rd;
    adskUID_e.o = ro;	// ray origin = camera position
    adskUID_e.d = rd;	// ray direction is the vector from the cam pos through the point on the imaginary screen
	vec4 col = adskUID_Lights(adskUID_e, adskUID_time * adskUID_flicker_speed, adskUID_time * adskUID_motion_speed); // lights falling down
	
	//adding a bit of noise 
	vec3 grain = adskUID_hash33(vec3(vertex.xy*20., vertex.z + adskUID_time));
	col.rgb *= mix(col.rgb, grain, 0.2);
	col = adsk_getBlendedValue( adskUID_blendModes, source, vec4(col.rgb, source.a));
	
	return col;
}