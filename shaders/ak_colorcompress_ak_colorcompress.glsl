uniform float adsk_result_w;
uniform float adsk_result_h;
uniform sampler2D front;
uniform sampler2D matte;
uniform sampler2D selective;

uniform vec3 color_target;
uniform float hue_strength;
uniform float sat_strength;
uniform float lum_strength;

uniform int strength_curve;

float adskEvalDynCurves(int curve,float x);
vec3 adsk_rgb2hsv(vec3 rgb);
vec3 adsk_hsv2rgb(vec3 hsv);

float hue_distance(vec3 a,vec3 b)
{
  return(min(abs(a.r-b.r),1.0-abs(a.r-b.r))); 
}

vec3 compress_hue(vec3 current,vec3 ref,float sel) 
{
  float old_hue      = current.r;
  float new_hue      = old_hue;
  float ref_hue      = ref.r;
  float distance     = hue_distance(current,ref);

  // reduce distance by strength (in percent)
  float new_distance = distance - distance * (1.0 -adskEvalDynCurves(strength_curve,hue_strength * sel / 100.0));

  if(old_hue < ref_hue && abs(ref_hue - old_hue) < 0.5 ||
     old_hue > ref_hue && abs(ref_hue - old_hue) > 0.5)
  {
    new_hue = old_hue + new_distance;
    new_hue = (new_hue > 1.0)? new_hue : new_hue-1.0;    
  } 
  else
  {
    new_hue = old_hue - new_distance;
    new_hue = (new_hue < 0.0)? new_hue : new_hue+1.0;
  }

  return(vec3(new_hue,current.g,current.b));
}
 
vec3 compress_sat(vec3 current,vec3 ref,float sel)
{
  float old_sat      = current.g;
  float new_sat      = old_sat;
  float ref_sat      = ref.g;
  float distance     = abs(current.g - ref.g);
  float new_distance = distance - distance * (1.0 - adskEvalDynCurves(strength_curve,sat_strength * sel / 100.0));

  new_sat += (old_sat < ref_sat)? new_distance : -new_distance;

  return(vec3(current.r,clamp(new_sat,0.0,1.0),current.b));
}

vec3 compress_lum(vec3 current,vec3 ref,float sel)
{
  float old_lum      = current.b;
  float new_lum	     = old_lum;
  float ref_lum      = ref.b;
  float distance     = abs(old_lum - ref_lum);
  float new_distance = distance - distance * (1.0 - adskEvalDynCurves(strength_curve,lum_strength * sel / 100.0));

  new_lum += (old_lum < ref_lum)? new_distance : -new_distance;

  return(vec3(current.r,current.g,clamp(new_lum,0.0,1.0)));
}

void main(void)
{
  vec2 res  	= vec2(adsk_result_w,adsk_result_h);
  vec2 uv       = gl_FragCoord.xy / res.xy;
  vec4 in1      = texture2D(front,uv);
  float matte   = texture2D(matte,uv).r;
  float sel     = texture2D(selective,uv).r;

  vec3 ref     = adsk_rgb2hsv(vec3(color_target));
  vec3 current = adsk_rgb2hsv(vec3(in1.rgb));

  current = compress_hue(current,ref,sel);
  current = compress_sat(current,ref,sel);
  current = compress_lum(current,ref,sel);

  gl_FragColor = mix(in1,vec4(adsk_hsv2rgb(current),1.0),matte);
}


