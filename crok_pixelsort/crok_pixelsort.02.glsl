#version 120
// based on https://www.shadertoy.com/view/XsBfRG

uniform sampler2D adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h;

float gray( vec3 c ) {
  return dot( c, vec3( 0.299, 0.587, 0.114 ) );
}

void main()
{
   vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
   vec3 c = texture2D(adsk_results_pass1, uv).rgb;
   c.r = gray(c);
   gl_FragColor = vec4(c.r);
}
