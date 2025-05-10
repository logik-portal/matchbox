#version 120

uniform sampler2D adsk_results_pass1, adsk_results_pass5;
uniform float adsk_result_w, adsk_result_h;
uniform float amount;
void main()
{
   vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
   vec4 o = texture2D(adsk_results_pass1, uv);
   vec4 b = texture2D(adsk_results_pass5, uv);
   vec4 c = o - b;
   c = mix(o, o - c, amount);
   gl_FragColor = c;
}
