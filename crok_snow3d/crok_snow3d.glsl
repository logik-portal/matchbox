// based on https://www.shadertoy.com/view/4tSSzt by FabriceNeyret2
// using the base ray-marcher of Trisomie21: https://www.shadertoy.com/view/4tfGRB#
// bias code by Dominik Schmid https://www.shadertoy.com/view/llBSWc

vec3 adsk_getVertexPosition();
vec3 adsk_getCameraPosition();
vec3 adsk_getLightPosition();
vec3 adsk_getLightDirection();
vec3 adsk_getLightTangent();
vec3 adsk_getLightColour();
vec3 adsk_getDiffuseMapCoord();
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor ); 

float adsk_getTime();
float adsk_getLuminance ( vec3 rgb );

uniform float adskUID_Speed;
uniform float adskUID_Offset;
uniform float adskUID_amount, adskUID_size, adskUID_max_rad;
uniform vec3 adskUID_speed;
uniform float adskUID_bias_adj;
uniform int adskUID_blendModes;
uniform int adskUID_style;

float adskUID_time = adsk_getTime() * 0.005 * adskUID_Speed + adskUID_Offset;

#define adskUID_r(v,t) v *= mat2( C = cos((t)*adskUID_time), S = sin((t)*adskUID_time), -S, C )

float adskUID_smin( float a, float b )
{
    return min(a,b);
}

float adskUID_bias(float x, float b) 
{
    b = -log2(1.0 - b);
    return 1.0 - pow(1.0 - pow(x, 1./b), b);
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
	ro /= 100.;
	vec3 rd = dir * lightbasis;
		
	vec2 w = uv.xy;
	vec4 col = vec4(0.0);
	
    float C,S,radius,r1,x,x1,i0;
    vec4 p = vec4(w,0,1)-.5, d,p2, u,t,t1,M,m; p.x-=.4;
         
    d.xyz = rd;
    p.xyz = -ro;
    p.xyz += adskUID_time * adskUID_speed;
	
	// snow style 
	if ( adskUID_style == 0)
	{
		
	}
	
   
    for (float i=1. * adskUID_amount; i>0.; i-=.01)  
    { x = 1e3;
     for(float j=0.; j<=1.; j++) {
        u = floor(p/8.+11.5*j); 
        u = fract(1234.*sin(78.*(u+u.yzxw)));
		
        p2 = p+11.5*j; 
         if (j==0.) p2.x -= 15.*adskUID_time*(2.*u.y-1.);
         else       p2.y -= 15.*adskUID_time*(2.*u.z-1.); 
        u = floor(p2/8.); t = mod(p2, 8.)-4.;
        u = fract(1234.*sin(78.*(u+u.yzxw)*vec4(1,-12,8,-4)));
        
              
        radius = (adskUID_size* 0.1 + 0.1 * u.w) ; 
		r1 =3.15;
		/*
		if ( radius >= adskUID_max_rad * 0.01 )
			radius = adskUID_max_rad * 0.01 ;
		*/
		
	    t1 = t+r1*sin(1.*adskUID_time+u*6.);               x1 = length(t .xyz)-radius;    x = adskUID_smin(x,x1);
	    t1 = t+r1*sin(2.*adskUID_time-u*6.); adskUID_r(t1.xy,u.z); x1 = length(t1.xyz)-radius*.8; x = adskUID_smin(x,x1);
	    t1 = t+r1*sin(3.*adskUID_time+u*3.); adskUID_r(t1.yz,u.x); x1 = length(t1.xyz)-radius*.5; x = adskUID_smin(x,x1);
		
        if(x<.01) break;
      }
    
        if(x<.01) {i0=i; break; }
    
        p -= d*x;
     }
    if(x<.01)
		{
			col = i0*i0*(1.+.2*t);
		}
		float lum = adsk_getLuminance(col.rgb);
		lum = adskUID_bias(lum, adskUID_bias_adj);

		vec4 c = adsk_getBlendedValue( adskUID_blendModes, source, vec4(vec3(lum), source.a));
		return c;
	}