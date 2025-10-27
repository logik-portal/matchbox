#version 120

uniform sampler2D adsk_results_pass1, adsk_results_pass3 ;
uniform float blur, adsk_result_w, adsk_result_h;
uniform bool depthMap;


void main()
{
  vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
  vec3 c = texture2D(adsk_results_pass1, uv).rgb;
  float d = texture2D(adsk_results_pass3, uv).a;
  if ( depthMap )
  c = vec3(d);

   gl_FragColor = vec4( c, d );
}
