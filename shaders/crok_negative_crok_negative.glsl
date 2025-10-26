#version 120

uniform sampler2D front, matte;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

//Forward Declaration
float adsk_getLuminance( vec3 rgb);
vec3 adsk_rgb2hsv( vec3 rgb );
vec3 adsk_hsv2rgb( vec3 hsv );
vec3 adsk_rgb2yuv( vec3 rgb );
vec3 adsk_yuv2rgb( vec3 yuv );

uniform bool neg_front;
uniform bool neg_matte;
uniform bool neg_sat;
uniform bool neg_lum;


void main( void )
{
  vec2 uv = (gl_FragCoord.xy / res.xy);
  vec3 c = texture2D(front, uv).rgb;
  float m = texture2D(matte, uv).r;

  // invert matte
  if ( neg_matte )
    m = 1.0 - m;
  // invert front
  if ( neg_front )
    c = 1.0 - c;
  // invert luminance
  if ( neg_lum )
  {
    c = adsk_rgb2yuv( c.rgb ) ;
    c.r = 1.0 - c.r;
    c = adsk_yuv2rgb(c.rgb);
  }
  // invert saturation
  if ( neg_sat )
  {
    c = adsk_rgb2hsv( c.rgb ) ;
    c.g = 1.0 - c.g;
    c = adsk_hsv2rgb(c.rgb);
  }

	gl_FragColor = vec4(c, m);
}
