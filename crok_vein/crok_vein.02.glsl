#version 120
// based on https://www.shadertoy.com/view/Mtc3Dj by cornusammonis

uniform sampler2D adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform vec3 bg,fg;

void main( void )
{
    vec2 uv = gl_FragCoord.xy/res.xy;
    float d = length(texture2D(adsk_results_pass1, uv).xy);
    //vec3 tx = texture2D(iChannel1, uv, 1.0).xyz;
    vec3 col = mix(bg, fg, 5.0*d);
	gl_FragColor = vec4(col, 1.0);
}
