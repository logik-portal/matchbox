// based on https://www.shadertoy.com/view/4tfSDr by gongenhao

vec3 adsk_getDiffuseMapCoord();
vec4 adsk_getDiffuseMapValue(in vec2 texCoord);
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor ); 

uniform float adskUID_sigma;

float adskUID_sigma_spatial = 0.1;
float adskUID_filter_window = 0.15;

float adskUID_sigma_color = adskUID_sigma + 0.2;

float adskUID_random(vec3 scale, float seed) {
    return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
}

vec3 adskUID_NLFilter(vec2 uv, float sigma_spatial,float sigma_color)
{
	float wsize = adskUID_filter_window * 0.00214285714286;
    vec3 res_color = vec3(0.0,0.0,0.0);
    float res_weight = 0.0;
	vec3 center_color = adsk_getDiffuseMapValue(uv.xy).rgb;
    float sigma_i=0.5*wsize*wsize/sigma_spatial/sigma_spatial;
    float offset = adskUID_random(vec3(12.9898, 78.233, 151.7182), 0.0);
    float offset2 = adskUID_random(vec3(112.9898, 178.233, 51.7182), 0.0);    
    for (float i = -7.0; i <= 7.0; i++) {
        for (float j= -7.0; j<= 7.0; j++) {
            vec2 uv_sample = uv.xy+vec2(float(i+offset-0.5)*wsize,float(j+offset-0.5)*wsize);
			vec3 tmp_color = adsk_getDiffuseMapValue(uv_sample).rgb;   
            vec3 diff_color = (tmp_color-center_color);
            float tmp_weight = exp(-(i*i+j*j)*sigma_i);
            tmp_weight *= exp(-(dot(diff_color,diff_color)/2.0/sigma_color/sigma_color));
            res_color += tmp_color * tmp_weight;
            res_weight += tmp_weight;   
        }
    }
    vec3 res = res_color/res_weight;
    return res;
}

vec4 adskUID_lightbox(vec4 source)
{
	vec3 uv = adsk_getDiffuseMapCoord();
    vec3 result = adskUID_NLFilter(uv.xy*vec2(1.0,1.0),adskUID_sigma_spatial * 0.01,adskUID_sigma_color * 0.04);    
	vec3 base = adsk_getDiffuseMapValue(uv.xy*vec2(1.0,-1.0)).rgb;
    result = mix(base,result,1.0);
	return vec4(result, source.a);
}
