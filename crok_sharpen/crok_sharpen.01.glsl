// based on https://www.shadertoy.com/view/MtcSzH by ttoinou
#version 120

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

void main( void )
{
    gl_FragColor = texture2D(front, gl_FragCoord.xy / res.xy);
}
