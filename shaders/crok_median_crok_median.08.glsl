#version 120
// based on https://www.shadertoy.com/view/MtcSzH by ttoinou
uniform sampler2D adsk_results_pass7;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

// continuous gradient
// https://www.shadertoy.com/view/XtK3Dd
#define GRADIENT_RADIUS (1)
#define gradientInput adsk_results_pass7
#define gradientDirectionX (true)

#define GRADIENT_RADIUSf float(GRADIENT_RADIUS)
#define GRADIENT_RADIUSi22f 4.

void main()
{
    gl_FragColor = vec4(0.);

    for( int i = -GRADIENT_RADIUS ; i <= GRADIENT_RADIUS ; i++ ){
    	for( int j = -GRADIENT_RADIUS ; j <= GRADIENT_RADIUS ; j++ ){
            gl_FragColor += (gradientDirectionX ? float(i) : float(j))
                *exp(-float(i*i + j*j)*GRADIENT_RADIUSi22f)/GRADIENT_RADIUSf
                *texture2D(gradientInput,(gl_FragCoord.xy + vec2(i, j)) / res.xy);
        }

    }
}
