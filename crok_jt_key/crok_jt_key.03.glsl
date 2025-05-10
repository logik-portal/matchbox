#version 120

// create the clean green / bluescreen
uniform sampler2D front, adsk_results_pass1, adsk_results_pass2;
uniform float adsk_result_w, adsk_result_h;

void main()
{
   vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
   vec3 f = texture2D(front, uv).rgb;
   float m = texture2D(adsk_results_pass2, uv).r;
   float ext_m = texture2D(adsk_results_pass1, uv).a;

  // multiply fg by matte
  f = f * m;

  gl_FragColor = vec4(f, m);
}
