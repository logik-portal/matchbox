// based on https://www.shadertoy.com/view/XdfGz8
// volume explosion shader
// simon green / nvidia 2012
// http://developer.download.nvidia.com/assets/gamedev/files/gdc12/GDC2012_Mastering_DirectX11_with_Unity.pdf

// sorry, port from HLSL!
#define float3 vec3
#define float4 vec4

vec3 adsk_getVertexPosition();
vec3 adsk_getCameraPosition();
vec3 adsk_getLightPosition();
vec3 adsk_getLightDirection();
vec3 adsk_getLightTangent();
vec3 adsk_getLightColour();
mat4 adsk_getModelViewMatrix();
mat4 adsk_getModelViewInverseMatrix();
vec3 adsk_getComputedDiffuse();
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor ); 
vec3 adsk_hsv2rgb( vec3 hsv );
float adsk_getLuminance( vec3 rgb );

uniform float adskUID_speed, adskUID_offset;

float adsk_getTime();
float adskUID_time = adsk_getTime() * 0.05 * adskUID_speed + adskUID_offset;

uniform vec3 adskUID_colourWheel1;
uniform vec3 adskUID_colourWheel2;
uniform vec3 adskUID_colourWheel3;
uniform int adskUID_maxSteps; // = 64;
uniform float adskUID_minStep; // = 0.001;
uniform float adskUID_SphereRadius;
uniform float adskUID_StepDistanceScale; // = 0.5;
uniform float adskUID_DistThreshold; // = 0.005;
uniform int adskUID_aaSteps;
uniform int adskUID_VolumeSteps; // = 32;
uniform int adskUID_blendModes;
uniform float adskUID_Density; // = 0.1;
uniform float adskUID_NoiseFreq; // = 4.0;
uniform float adskUID_NoiseAmp; // = -0.5;
uniform vec3 adskUID_NoiseAnim;

//float adskUID_SphereRadius = 1.0;
#define luma(col) dot(col, vec3(0.3086, 0.6094, 0.0820))

// We are using this function to map the Hue and Gain of the Colour Wheel in HSV to an RGB value
vec3 adskUID_getRGB( float hue )
{
	return adsk_hsv2rgb( vec3( hue, 1.0, 1.0 ) );
}

// contrast / saturation adjustments by  Miles
vec3 adskUID_adjust_contrast(vec3 col, vec4 con)
{
vec3 c = con.rgb * vec3(con.a);
vec3 t = (vec3(1.0) - c) / vec3(2.0);
t = vec3(.18);

col = (1.0 - c.rgb) * t + c.rgb * col;

return col;
}

vec3 adskUID_adjust_saturation(vec3 col, float c)
{
    float l = luma(col);
    col = (1.0 - c) * l + c * col;

    return col;
}

// matrix to rotate the noise octaves
mat3 adskUID_m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );

float adskUID_hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float adskUID_noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( adskUID_hash(n+  0.0), adskUID_hash(n+  1.0),f.x),
                        mix( adskUID_hash(n+ 57.0), adskUID_hash(n+ 58.0),f.x),f.y),
                    mix(mix( adskUID_hash(n+113.0), adskUID_hash(n+114.0),f.x),
                        mix( adskUID_hash(n+170.0), adskUID_hash(n+171.0),f.x),f.y),f.z);
    return res;
}


float adskUID_fbm( vec3 p )
{
	    float f;
	    f = 0.506*adskUID_noise( p ); p = adskUID_m*p*2.05;
	    f += 0.3000*adskUID_noise( p ); p = adskUID_m*p*2.02;
	    f += 0.2500*adskUID_noise( p ); p = adskUID_m*p*2.03;
	    f += 0.1250*adskUID_noise( p ); p = adskUID_m*p*2.01;
	    f += 0.0325*adskUID_noise( p );
	    f += 0.0125*adskUID_noise( p );
	    p = adskUID_m*p*2.02; f += 0.03125*abs(adskUID_noise( p ));	
	    return f/0.9375;
}


// distance field stuff
float adskUID_sphereDist(float3 p, float4 sphere)
{
    return length(p - sphere.xyz) - sphere.w;
}

// returns signed distance to nearest surface
// displace is displacement from original surface (0, 1)
float adskUID_distanceFunc(float3 p, out float displace)
{	
	float d = length(p) - 0.5 * adskUID_SphereRadius;	// distance to sphere
	//float d = length(p) - (sin(adskUID_time*0.25)+0.5);	// animated radius
	
	// offset distance with pyroclastic noise
	//p = normalize(p) * _SphereRadius;	// project noise point to sphere surface
	displace = adskUID_fbm(p*adskUID_NoiseFreq - adskUID_NoiseAnim * adskUID_time);
	d += displace * -adskUID_NoiseAmp;
	
	return d;
}

// calculate normal from distance field
float3 adskUID_dfNormal(float3 pos)
{
    float eps = 0.001;
    float3 n;
    float s;

    float d = adskUID_distanceFunc(pos, s);
    n.x = adskUID_distanceFunc( float3(pos.x+eps, pos.y, pos.z), s ) - d;
    n.y = adskUID_distanceFunc( float3(pos.x, pos.y+eps, pos.z), s ) - d;
    n.z = adskUID_distanceFunc( float3(pos.x, pos.y, pos.z+eps), s ) - d;

    return normalize(n);
}

// color gradient 
float4 adskUID_gradient(float x)
{
	const float4 c0 = float4(4, 4, 4, 1);	// hot white
	//const float4 adskUID_c1 = float4(1, 1, 0, 1);	// yellow
	//const float4 adskUID_c2 = float4(1, 0, 0, 1);	// red
	//const float4 adskUID_c3 = float4(0.2, 0.2, 0.2, 1);	// grey
	
    vec4 adskUID_c1 = vec4(adskUID_getRGB( adskUID_colourWheel1.x / 360.0 ) * vec3( adskUID_colourWheel1.y * 0.01), adskUID_colourWheel1.z * 0.01);
    vec4 adskUID_c2 = vec4(adskUID_getRGB( adskUID_colourWheel2.x / 360.0 ) * vec3( adskUID_colourWheel2.y * 0.01), adskUID_colourWheel2.z * 0.01);
    vec4 adskUID_c3 = vec4(adskUID_getRGB( adskUID_colourWheel3.x / 360.0 ) * vec3( adskUID_colourWheel3.y * 0.01), adskUID_colourWheel3.z * 0.01);
	
	adskUID_c1.rgb = adskUID_adjust_saturation(adskUID_c1.rgb, adskUID_colourWheel1.z * 0.01);
	adskUID_c2.rgb = adskUID_adjust_saturation(adskUID_c2.rgb, adskUID_colourWheel2.z * 0.01);
	adskUID_c3.rgb = adskUID_adjust_saturation(adskUID_c3.rgb, adskUID_colourWheel3.z * 0.01);
	
	float t = fract(x*3.0);
	
	float4 c;
	if (x < 0.3333) {
		c =  mix(c0, adskUID_c1, t);
	} else if (x < 0.6666) {
		c = mix(adskUID_c1, adskUID_c2, t);
	} else {
		c = mix(adskUID_c2, adskUID_c3, t);
	}
	return c;
}

// shade a point based on position and displacement from surface
float4 adskUID_shade(float3 p, float displace)
{	
	// lookup in color gradient
	displace = displace*1.5 - 0.2;
	displace = clamp(displace, 0.0, 0.99);
	float4 c = adskUID_gradient(displace);
	
	// lighting
	float3 n = adskUID_dfNormal(p);
	float diffuse = n.z*0.5+0.5;
	c.rgb = mix(c.rgb, c.rgb*diffuse, clamp((displace-0.5)*2.0, 0.0, 1.0));
	return c;
}

// procedural volume
// maps position to color
float4 adskUID_volumeFunc(float3 p)
{
	float displace;
	float d = adskUID_distanceFunc(p, displace);
	float4 c = adskUID_shade(p, displace);
	return c;
}

// sphere trace
// returns hit position
float3 adskUID_sphereTrace(float3 rayOrigin, float3 rayDir, out bool hit, out float displace)
{
	float3 pos = rayOrigin;
	hit = false;
	displace = 5.0;	
	float d;
	float disp;
	for(int i=0; i < adskUID_maxSteps; i++) {
		d = adskUID_distanceFunc(pos, disp);
        	if (d < adskUID_DistThreshold * 0.005) {
			hit = true;
			displace = disp;
        	}
			pos += rayDir*d*adskUID_StepDistanceScale;
	}
	
	return pos;
}

float adskUID_rand(vec2 p) {
	return fract(sin(dot(p ,vec2(12.9898,78.233))) * 43758.5453);
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
	float z = length(vertex-camera);
    vec3 ro = camera - light;
    ro *= lightbasis;
	ro *= 0.003;
	z *= 0.003;
	vec3 rd = dir * lightbasis;
    ro += rd;
          
    // sphere trace distance field
    bool hit;
    float displace;
    vec3 hitPos = vec3(0.0);
    vec4 col = vec4(0, 0, 0, 1);
	
	// add AA
	if ( adskUID_aaSteps == 1 )
	{
		hitPos = adskUID_sphereTrace(ro, rd, hit, displace);
	    if (hit) {
			// shade
			col += adskUID_shade(hitPos, displace);
	    }
	}
	
	else
	{
		for(int i=0; i<adskUID_aaSteps; i++)
		{
			float aa_offset = adskUID_rand(vec2(i, i));
			hitPos = adskUID_sphereTrace((ro + aa_offset * 0.001), rd, hit, displace);
  
		    if (hit) {
				// shade
				col += adskUID_shade(hitPos, displace);
		    }
		}
		col /= float(adskUID_aaSteps);
	}


	col = adsk_getBlendedValue( adskUID_blendModes, source, vec4(col.rgb, source.a));

	return vec4(col.rgb, source.a);
}
