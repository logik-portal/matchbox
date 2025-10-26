// based on https://www.shadertoy.com/view/Msf3Dj
// sphere tracing transparent stuff
// @simesgreen

vec3 adsk_getVertexPosition();
vec3 adsk_getCameraPosition();
vec3 adsk_getDiffuseMapCoord();
vec4 adsk_getDiffuseMapValue(in vec2 texCoord);
vec3 adsk_getLightPosition();
vec3 adsk_getLightDirection();
vec3 adsk_getLightTangent();
vec3 adsk_getLightColour();
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor ); 
vec3 adsk_hsv2rgb( vec3 hsv );
float adsk_getLuminance( vec3 rgb );

uniform int adskUID_maxSteps;
uniform int adskUID_aaSteps;
uniform float adskUID_minStep;
uniform float adskUID_Detail;
uniform float adskUID_brightness;
uniform float adskUID_contrast;
uniform float adskUID_saturation;
uniform vec3 adskUID_colourWheel1;
//uniform vec3 adskUID_colourWheel2;
uniform int adskUID_blendModes;
uniform int adskUID_noise_version;
uniform float adskUID_noise_offset;
uniform float adskUID_gamma;
uniform float adskUID_scale;

const float adskUID_hitThreshold = 0.01;
const vec3 adskUID_translucentColor = vec3(0.8, 0.2, 0.1)*3.0;
const vec3 adskUID_LumCoeff = vec3(0.2125, 0.7154, 0.0721);
const mat3 adskUID_m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );
									
// We are using this function to map the Hue and Gain of the Colour Wheel in HSV to an RGB value
vec3 adskUID_getRGB( float hue )
{
	return adsk_hsv2rgb( vec3( hue, 10000.0, 10000.0 ) );
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

// hash based 3d value noise
float adskUID_hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float adskUID_noise( vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*((adskUID_Detail+1.0)-adskUID_Detail*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;

    return mix(mix(mix( adskUID_hash(n+  0.0), adskUID_hash(n+  1.0),f.x),
           mix( adskUID_hash(n+ 57.0), adskUID_hash(n+ 58.0),f.x),f.y),
           mix(mix( adskUID_hash(n+113.0), adskUID_hash(n+114.0),f.x),
           mix( adskUID_hash(n+170.0), adskUID_hash(n+171.0),f.x),f.y),f.z) *2.0 - 1.0;
	   }

float adskUID_fbm_4( vec3 p )
{
	float f;
	f = 0.75000*adskUID_noise( p ); p = adskUID_m*p*2.01;
	f += 0.62500*adskUID_noise( p ); p = adskUID_m*p*2.04;
	f += 0.5000*adskUID_noise( p ); p = adskUID_m*p*2.02;
	f += 0.37500*adskUID_noise( p ); p = adskUID_m*p*2.015;
	f += 0.2500*adskUID_noise( p ); p = adskUID_m*p*2.03;
	f += 0.1250*adskUID_noise( p ); p = adskUID_m*p*2.01;
	f += 0.0625*adskUID_noise( p ); p = adskUID_m*p*2.003;
	f += 0.0315*adskUID_noise( p );
	return f;
}

float adskUID_fbm_3( vec3 p )
{
    float f;
	f = 0.5500*adskUID_noise( p ); p = adskUID_m*p*2.03;
	f += 0.4500*adskUID_noise( p ); p *= adskUID_m*2.02; //p = p*2.02;
    f += 0.3500*adskUID_noise( p ); p *= adskUID_m*2.03; //p = p*2.03;
    f += 0.2500*adskUID_noise( p ); p *= adskUID_m*2.03; //p = p*2.03;
    f += 0.1250*adskUID_noise( p ); p *= adskUID_m*2.01; //p = p*2.01;
    f += 0.0625*adskUID_noise( p ); 	
    return f;
}


float adskUID_fbm_2( vec3 p )
{
    float f;
	f = 0.62500*adskUID_noise( p ); p = adskUID_m*p*2.03;
	f += 0.5000*adskUID_noise( p ); p *= adskUID_m*2.02; //p = p*2.02;
    f += 0.2500*adskUID_noise( p ); p *= adskUID_m*2.03; //p = p*2.03;
    f += 0.1250*adskUID_noise( p ); p *= adskUID_m*2.01; //p = p*2.01;
    f += 0.0625*adskUID_noise( p ); 	
    return f;
}


float adskUID_fbm_1( vec3 p )
{
    float f;
    f  = 0.5000*adskUID_noise( p ); p *= adskUID_m*2.02; //p = p*2.02;
    f += 0.2500*adskUID_noise( p ); p *= adskUID_m*2.03; //p = p*2.03;
    f += 0.1250*adskUID_noise( p ); p *= adskUID_m*2.01; //p = p*2.01;
    f += 0.0625*adskUID_noise( p ); 	
    return f;
}

// distance to scene
float adskUID_scene(vec3 p)
{          
    float d;
	vec3 np = p + vec3(0.0);
	if ( adskUID_noise_version == 1 )
		d = adskUID_fbm_1(np)*0.8 + 0.2 * adskUID_noise_offset;
	else if ( adskUID_noise_version == 2 )
		d = adskUID_fbm_2(np)*0.8 + 0.2 * adskUID_noise_offset;
	else if ( adskUID_noise_version == 3 )
		d = adskUID_fbm_3(np)*0.8 + 0.2 * adskUID_noise_offset;
	else
		d = adskUID_fbm_4(np)*0.8 + 0.2 * adskUID_noise_offset;
	return d;
}

// trace ray using regular sphere tracing
// returns position of closest surface
vec3 adskUID_trace(vec3 ro, vec3 rd, out bool hit)
{
    hit = false;
    vec3 pos = ro;
    for(int i=0; i<adskUID_maxSteps; i++)
    {
		float d = adskUID_scene(pos);
		if (abs(d) < adskUID_hitThreshold) {
			hit = true;
		}
		pos += d*rd;
    }
    return pos;
}

// trace all the way through the scene,
// keeping track of distance traveled inside volume
vec3 adskUID_traceInside(vec3 ro, vec3 rd, out bool hit, out float insideDist)
{
    hit = false;
	insideDist = 0.0;	
    vec3 pos = ro;
	vec3 hitPos = pos;
    for(int i=0; i<adskUID_maxSteps; i++)
    {
		float d = adskUID_scene(pos);
		d = max(abs(d), adskUID_minStep * 0.001) * sign(d); // enforce minimum step size
		
		if (d < adskUID_hitThreshold && !hit) {
			// save first hit
			hitPos = pos;
			hit = true;
		}
		
		if (d < 0.0) {
			// sum up distance inside
			insideDist += -d;
		}
		pos += abs(d)*rd;
    }
    return hitPos;
}

vec3 adskUID_background(vec3 rd)
{
     return vec3(1.0);
}

vec4 adskUID_tint_color = vec4(adskUID_getRGB( adskUID_colourWheel1.x / 360.0 ) * vec3( adskUID_colourWheel1.y * 0.01), adskUID_colourWheel1.z * 0.01);
// vec3 adskUID_translucent_color = adskUID_getRGB( adskUID_colourWheel2.x / 360.0 ) * vec3( adskUID_colourWheel2.y * 0.01);

float adskUID_rand(vec2 p) {
	return fract(sin(dot(p ,vec2(12.9898,78.233))) * 43758.5453);
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
	float z = length(vertex-camera);
    vec3 ro = camera - light;
    ro *= lightbasis;
	ro /= 200.0;
	z /= 200.0;
	vec3 rd = dir * lightbasis;
    ro += rd;
          
    // trace ray
    bool hit;
	float dist;
    vec4 col = vec4(0.0);
    vec3 hitPos = vec3(0.0);
	
	// add AA
	if ( adskUID_aaSteps == 1 )
	{
		hitPos = adskUID_traceInside(ro, rd, hit, dist);
		col.rgb += exp(-dist*dist*adskUID_translucentColor.rgb);
	}
	
	else
	{
		for(int i=0; i<adskUID_aaSteps; i++)
		{
			float aa_offset = adskUID_rand(vec2(i, i));
			hitPos = adskUID_traceInside((ro + aa_offset * 0.001), rd, hit, dist);
			col.rgb += exp(-dist*dist*adskUID_translucentColor.rgb);
		}
		col /= float(adskUID_aaSteps);
	}
		
	//hitPos = adskUID_traceInside(ro, rd, hit, dist);
	// exponential fall-off:
	//col.rgb = exp(-dist*dist*adskUID_translucentColor.rgb);

	col.rgb = clamp(col.rgb, 0.0, 1.0);
  	col.rgb = pow(abs(col.rgb), vec3(1.0 / adskUID_gamma));
	float intensity = adsk_getLuminance( col.rgb );
	col.rgb = mix(vec3(intensity), col.rgb, adskUID_saturation);
	col.rgb = adskUID_adjust_contrast(col.rgb, vec4(adskUID_contrast));
	col.rgb = col.rgb - 1.0 + adskUID_brightness;
	adskUID_tint_color.rgb = clamp(adskUID_tint_color.rgb, 0.0, 1.0);
	col.rgb = mix(col.rgb, adskUID_tint_color.rgb * col.rgb, adskUID_tint_color.a);
	col = adsk_getBlendedValue( adskUID_blendModes, source, vec4(col.rgb, source.a));
	return vec4(col.rgb, source.a);
}