#version 120

uniform sampler2D adsk_results_pass4;
uniform float adsk_result_w, adsk_result_h, adsk_front_w, adsk_front_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform float vhs_res; // = 0.197;

void main( void )
{
  vec2 p = (gl_FragCoord.xy / res.xy ) * vhs_res;
  vec4 col = texture2D( adsk_results_pass4, p );
  gl_FragColor = vec4(col.rgb,1.0 );


}
