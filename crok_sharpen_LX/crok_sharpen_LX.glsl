vec3 adsk_getDiffuseMapCoord();
vec4 adsk_getDiffuseMapValue(in vec2 texCoord);
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor ); 

uniform float adskUID_sharpness, adskUID_resolution;
uniform int adskUID_blendModes;

vec4 adskUID_lightbox(vec4 source)
{
	vec3 uv = adsk_getDiffuseMapCoord();
    
	vec2 step = 1.0 / vec2(5000., 5000.) * 1.0 / adskUID_resolution * 3.0;
	
	vec3 texA = adsk_getDiffuseMapValue(uv.xy + vec2(-step.x, -step.y) * 1.5 ).rgb;
	vec3 texB = adsk_getDiffuseMapValue(uv.xy + vec2( step.x, -step.y) * 1.5 ).rgb;
	vec3 texC = adsk_getDiffuseMapValue(uv.xy + vec2(-step.x,  step.y) * 1.5 ).rgb;
	vec3 texD = adsk_getDiffuseMapValue(uv.xy + vec2( step.x,  step.y) * 1.5 ).rgb;
   
    vec3 around = 0.25 * (texA + texB + texC + texD);
	vec3 center  = adsk_getDiffuseMapValue(uv.xy).rgb;
	
    
	vec3 col = center + (center - around) * adskUID_sharpness * 5.;
	vec4 fin_col = adsk_getBlendedValue( adskUID_blendModes, source, vec4(col.rgb, source.a));
	
	return fin_col;
}

