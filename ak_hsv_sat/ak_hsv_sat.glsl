uniform float adsk_result_w;
uniform float adsk_result_h;
uniform sampler2D front;
uniform sampler2D matte;
uniform sampler2D selective;

uniform vec3 color_ref;
uniform int strength_curve;
uniform int falloff_curve;
uniform bool falloff;

float adskEvalDynCurves(int curve,float x);
vec3 adsk_rgb2hsv(vec3 rgb);
vec3 adsk_hsv2rgb(vec3 hsv);

float hue_distance(vec3 a,vec3 b)
{
  return(min(abs(a.r-b.r),1.0-abs(a.r-b.r)));
}

vec3 adjust_sat(vec3 current,vec3 ref,float sel)
{
  float old_sat      = current.g;
  float distance     = hue_distance(current,ref);
  float new_sat;
  float sat_delta;
  float result;

  new_sat = old_sat * adskEvalDynCurves(strength_curve,old_sat);

  if(falloff) {
    sat_delta = abs(old_sat - new_sat) * (1.0 - distance * adskEvalDynCurves(falloff_curve,distance));
    result    = old_sat + sat_delta * (new_sat < old_sat? -1.0 : 1.0);
  } else {
    result = new_sat;
  }

  return(vec3(current.r,clamp(result * sel,0.0,1.0),current.b)); 
}

void main(void)
{
  vec2 res  	= vec2(adsk_result_w,adsk_result_h);
  vec2 uv       = gl_FragCoord.xy / res.xy;
  vec4 in1      = texture2D(front,uv);
  float matte   = texture2D(matte,uv).r;
  float sel     = texture2D(selective,uv).r;

  vec3 ref     = adsk_rgb2hsv(vec3(color_ref));
  vec3 current = adsk_rgb2hsv(vec3(in1.rgb));

  current = adjust_sat(current,ref,sel);

  gl_FragColor = mix(in1,vec4(adsk_hsv2rgb(current),1.0),matte);
}


