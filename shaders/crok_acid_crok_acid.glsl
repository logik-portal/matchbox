// based on http://glslsandbox.com/e#25386

vec3 adsk_getVertexPosition();
vec3 adsk_getCameraPosition();
vec3 adsk_getLightPosition();
vec3 adsk_getLightDirection();
vec3 adsk_getLightTangent();
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor ); 
vec3 adsk_hsv2rgb( vec3 hsv );
float adsk_getLuminance( vec3 rgb );

float adsk_getTime();
  
#define pepi  23.140692632779269005729086367949 //powe(pi);
#define chpi  11.59195327552152062775175205256  //cosh(pi)
#define pisq  9.8696044010893586188344909998762 //pi squared, pi^2
#define pi    3.1415926535897932384626433832795 //pi
#define e     2.7182818284590452353602874713526 //eulers number
#define hfpi  1.5707963267948966192313216916398 //half pi, 1/pi
#define trpi  1.0471975511965977461542144610932 //one third of pi, pi/3 
#define lgpi  0.4971498726941338543512682882909 //log(pi)       
#define rcpi  0.31830988618379067153776752674503// reciprocal of pi  , 1/pi  

const vec3 adskUID_LumCoeff = vec3(0.2125, 0.7154, 0.0721);

uniform float adskUID_brightness;
uniform float adskUID_gamma;
uniform float adskUID_contrast;
uniform float adskUID_saturation;
uniform vec3 adskUID_colourWheel1;
uniform int adskUID_blendModes;
uniform float adskUID_tint;
uniform vec3 adskUID_tint_col;

uniform int adskUID_detail;
uniform int adskUID_detail2;
uniform int adskUID_detail3;


// We are using this function to map the Hue and Gain of the Colour Wheel in HSV to an RGB value
vec3 adskUID_getRGB( float hue )
{
	return adsk_hsv2rgb( vec3( hue, 1.0, 1.0 ) );
}

// Real contrast adjustments by  Miles
vec3 adskUID_adjust_contrast(vec3 col, vec4 con)
{
vec3 c = con.rgb * vec3(con.a);
vec3 t = (vec3(1.0) - c) / vec3(2.0);
t = vec3(.18);

col = (1.0 - c.rgb) * t + c.rgb * col;

return col;
}

vec4 adskUID_tint_color = vec4(adskUID_getRGB( adskUID_colourWheel1.x / 360.0 ) * vec3( adskUID_colourWheel1.y * 0.01), adskUID_colourWheel1.z * 0.01);

vec3 adskUID_rotate(vec3 vec, vec3 axis, float ang)
{
    return vec * cos(ang) + cross(axis, vec) * sin(ang) + axis * dot(axis, vec) * (1.0 - cos(ang));
}

vec3 adskUID_pin(vec3 v)
{
    vec3 q = vec3(0.0);
    q.z = +sin(v.y)*0.5+0.5;
    q.x = +sin(v.z+0.66666667*pi)*0.5+0.5;
    q.y = +sin(v.x+1.33333333*pi)*0.5+0.5;
    return (q);
}

vec3 adskUID_spin(vec3 v)
{
    for(int i = 1; i <adskUID_detail2; i++)
    {
        v=adskUID_pin(adskUID_rotate((v),adskUID_pin(v),float(i*i)))*e;
    }
    return (v.xyz);
}

vec3 adskUID_fin(vec3 v)
{
	vec4 vt = vec4(v,(v.x+v.y+v.z)/pi);
	vec4 vs = vt;
	vt.xyz  += adskUID_pin(vs.xyz);
	vt.xyz  += adskUID_pin(vs.yzw);
	vt.xyz  += adskUID_pin(vs.zwx);
	vt.xyz  += adskUID_pin(vs.wxy);
	return adskUID_spin(vt.xyz/pisq);
}


vec3 adskUID_sfin(vec3 v)
{
    for(int i = 1; i < adskUID_detail3; i++)
    {
        v =(v+adskUID_fin(v*float(i)));
    }
    return (normalize((adskUID_fin(v.zxy)))+(adskUID_spin(v.zxy*rcpi)))/2.;
}

vec4 adskUID_lightbox(vec4 source)
{	
    vec3 camera = adsk_getCameraPosition();
    vec3 vertex = adsk_getVertexPosition();
    vec3 light = adsk_getLightPosition();
    vec3 lightdir = adsk_getLightDirection();
    vec3 lighttan = adsk_getLightTangent();
    vec3 lightbitan = cross(lightdir, lighttan);
    mat3 lightbasis = mat3(lighttan, -lightbitan, lightdir);
    vec3 dir = normalize(vertex - camera);
    vec3 ro = camera - light;
    ro *= lightbasis;
	ro /= 150.0;
	vec3 rd = dir * lightbasis;
    ro += rd;
	
	vec4 col = vec4(0.0);
	vec3 vx = camera;
	vec3 vt = vx;
	
	for(int i=1;i<adskUID_detail + 1;i++) 
	{
		vx += (rd*float(i));
		vt = abs(adskUID_sfin((vx+ro)*hfpi)-0.4)+0.1;
		
		col.rgb = mix(col.rgb*float(i)/pi,vt,e/(exp(abs(col.x+col.y+col.z+vt.x+vt.y+vt.z))));
	}
	col = normalize(col);
	
	col.rgb = clamp(col.rgb, 0.0, 1.0);
  	col.rgb = pow(abs(col.rgb), vec3(1.0 / adskUID_gamma));
	float intensity = adsk_getLuminance( col.rgb );
	col.rgb = mix(vec3(intensity), col.rgb, adskUID_saturation);
	col.rgb = adskUID_adjust_contrast(col.rgb, vec4(adskUID_contrast));
	col.rgb = col.rgb - 1.0 + adskUID_brightness;
	col.rgb = mix(col.rgb, adskUID_tint_color.rgb * col.rgb, adskUID_tint_color.a);
	col = adsk_getBlendedValue( adskUID_blendModes, source, vec4(col.rgb, source.a));
	return vec4(col.rgb, source.a) ;
}
