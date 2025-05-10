// based on https://www.shadertoy.com/view/MtcSzH by ttoinou
// continuous gradient
// https://www.shadertoy.com/view/XtK3Dd

#version 120

uniform sampler2D adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 iResolution = vec2(adsk_result_w, adsk_result_h);

#define GRADIENT_RADIUS (8)
#define PI           (3.14159265359)
#define LUMWEIGHT    (vec3(0.2126,0.7152,0.0722))
#define gradientInput adsk_results_pass1
#define gradientDirectionX (true)

#define GRADIENT_RADIUSf float(GRADIENT_RADIUS)
#define GRADIENT_RADIUSi22f 4./float(GRADIENT_RADIUS*GRADIENT_RADIUS)

void main( void )
{
    gl_FragColor = vec4(0.);

    for( int i = -GRADIENT_RADIUS ; i <= GRADIENT_RADIUS ; i++ ){
    	for( int j = -GRADIENT_RADIUS ; j <= GRADIENT_RADIUS ; j++ ){
            gl_FragColor += (gradientDirectionX ? float(i) : float(j))
                *exp(-float(i*i + j*j)*GRADIENT_RADIUSi22f)/GRADIENT_RADIUSf
                *texture2D(gradientInput,(gl_FragCoord.xy+vec2(i,j))/iResolution.xy);
        }

    }
}
