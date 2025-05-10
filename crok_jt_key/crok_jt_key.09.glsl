#version 120
// combining everything

uniform sampler2D front, background, ext_core_matte, despilled_bg, adsk_results_pass1, adsk_results_pass2, adsk_results_pass6, adsk_results_pass8;
uniform float adsk_result_w, adsk_result_h;
uniform float amount, ga_amount, blend_amount, con_amount;
uniform int type;
uniform int outp;
uniform	bool use_external_despilled_fg, use_ext_core_matte;


float adsk_getLuminance( in vec3 color );
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor );

float gamma(float src, float value){
  return pow( max( 0.0, src ), 1.0 / (value + 1.0));
}

// Real contrast adjustments by  Miles
float contrast(float col, float c_amount)
{
	float c = c_amount;
	float t = (1.0 - c) / 2.0;
	t = 0.5;
	col = (1.0 - c) * t + c * col;
return clamp(col, 0.0, 1.0);
}

void main (){
  vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
  vec3 org_fg = texture2D(front, uv).rgb; // original FG
  vec3 org_bg = texture2D(background, uv).rgb; // original BG
  vec3 despill_fg = texture2D(adsk_results_pass1, uv).rgb; // despilled FG
  vec3 despill_bg = texture2D(despilled_bg, uv).rgb; // external despilled BG
	vec3 cl_bg = texture2D(adsk_results_pass6, uv).rgb; // clean BG
  float m = texture2D(adsk_results_pass2, uv).r; // matte
  float m_blurred = texture2D(adsk_results_pass8, uv).r; // matte
  float e_c_m = texture2D(ext_core_matte, uv).r; // external core matte

  vec3 c = vec3(0.0);

// create difference of clean BG and desat clean BG
vec3 result = cl_bg;
vec3 suppressed = cl_bg;
if(type == 0)
  suppressed.g 		= min((cl_bg.r+cl_bg.b)*0.5, suppressed.g);
else if(type == 1)
  suppressed.b 		= min((cl_bg.g+cl_bg.r)*0.5, suppressed.b);
else if(type == 2)
  suppressed.r 		= min((cl_bg.g+cl_bg.b)*0.5, suppressed.r);
result = mix( cl_bg, suppressed, amount );

if ( use_external_despilled_fg )
  result = despill_bg;

vec4 c_bg_dif = adsk_getBlendedValue (19, vec4(cl_bg, 1.0), vec4(result, 1.0) );

// desaturate the clean bg
float c_bg_desat_dif = adsk_getLuminance(c_bg_dif.rgb);

// difference between despilled FG and org FG
vec4 c_fg_dif = adsk_getBlendedValue (19, vec4(org_fg, 1.0), vec4(despill_fg, 1.0) );

// desaturate the clean fg
float c_fg_desat_dif = adsk_getLuminance(c_fg_dif.rgb);

//divide fg by bg
float c_div_fb_bg = clamp(c_fg_desat_dif / c_bg_desat_dif, 0.0, 1.0);

// subtract despilled fg from org bg
vec3 c_bg_sub = org_bg - despill_fg;

// multiply subtracted fg__org_bg by divided fg_bg
vec3 c_mul_sfg_d_fg = c_bg_sub * c_div_fb_bg;

// add processed bg over despilled fg
c = c_mul_sfg_d_fg + despill_fg;

if ( use_ext_core_matte ){
  e_c_m = 1.0 - e_c_m;
  c = vec3(e_c_m * c + (1.0 - e_c_m) * mix(c, despill_fg, blend_amount));
  m_blurred = e_c_m;
}

else {
  // adjust fill matte gamma and contrast
  m_blurred = contrast(m_blurred, con_amount) * m_blurred;
  m_blurred = gamma(m_blurred, ga_amount);
  c = vec3(m_blurred * c + (1.0 - m_blurred) * mix(c, despill_fg, blend_amount));
}

if(outp == 0)
  c = c;
else if(outp == 1)
  c = despill_fg;
else if(outp == 2)
  c = cl_bg;
else if(outp == 3)
  c = org_fg;
else if(outp == 4)
  c = vec3(m);
else if(outp == 5)
  c = vec3(1.0 - m_blurred);
gl_FragColor = vec4(c, 1.0);
}
