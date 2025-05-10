// based on https://www.shadertoy.com/view/MtcSzH by ttoinou
// continuous gradient
// https://www.shadertoy.com/view/XtK3Dd

#version 120

uniform sampler2D adsk_results_pass1, adsk_results_pass2, adsk_results_pass3;
uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 iResolution = vec2(adsk_result_w, adsk_result_h);

//uniform bool version;

#define input 	adsk_results_pass1
#define inputDX adsk_results_pass2
#define inputDY adsk_results_pass3

// my take on Trilateral Filtering
// http://dl.acm.org/citation.cfm?id=882431

// Upgrading Bilateral Blur with Gradient
// https://www.shadertoy.com/view/MlVGW3
uniform int RADIUS; //  (12)
#define DIAMETER   (2*RADIUS+1)

// bigger theses coeff the more we take into account the space concerned
// shouldn't need to change it
// close to 0 => square-shaped
#define COORDCOEFF (1.41) // (1.41)

// if theses two == 0. => filter is a gaussian blur
// the closer to zero the blurier
// the bigger the more selective
float LUMCOEFF = 18; //   (18.)
float GRADCOEFF = 16.0; //  (16.)
int GRADIENT_RADIUS = 8; // (8)


// see line 84
// not confident in my calculus in buffB & buffC
#define LUMPLANECORRECTION (1.0) // (1.)
#define pow3(x,y)    (pow( max(x,0.) , vec3(y) ))
#define LUMWEIGHT    (vec4(0.2126,0.7152,0.0722,0.3333))
#define GRADIENT_RADIUSf float(GRADIENT_RADIUS)
#define GRADIENT_RADIUSi22f (4./float(GRADIENT_RADIUS*GRADIENT_RADIUS))
#define PI           (3.14159265359)
#define viewport(x) ( (x) /iResolution.xy)


void main( void )
{
	vec2 uv = viewport(gl_FragCoord.xy);

    vec4 thisColor = texture2D(input,uv);
    vec4 thisGradX = texture2D(inputDX,uv);
    vec4 thisGradY = texture2D(inputDY,uv);

    vec4 col = vec4(0.0);
    vec4 diffColorToGradient;
    vec4 diffGradientX;
    vec4 diffGradientY;
    float sum = 0.;
    float coeff;
    vec2 pos;
    vec4 color = vec4(0.);
    vec4 gradX = vec4(0.);
    vec4 gradY = vec4(0.);

    float GradCoeff2 = GRADCOEFF*GRADCOEFF;
    float LumCoeff2 = LUMCOEFF*LUMCOEFF;
    float CoordCoeff2 = COORDCOEFF*COORDCOEFF/float(RADIUS*RADIUS);

    for( int i = -RADIUS ; i <= RADIUS ; i++ ){
        for( int j = -RADIUS ; j <= RADIUS ; j++ ){

            pos = viewport(gl_FragCoord.xy+vec2(i,j));
            color = texture2D(input,pos);
            gradX = texture2D(inputDX,pos);
            gradY = texture2D(inputDY,pos);

            diffGradientX = thisGradX - gradX;
            diffGradientY = thisGradY - gradY;

            diffColorToGradient = thisColor - color
                // minus sign ? I must have made an error in buffB & buffC :-(
                - (thisGradX*float(i) + thisGradY*float(j))*GRADIENT_RADIUSi22f*LUMPLANECORRECTION;

            coeff = exp( -(
                // blur in coordinate space
                float(i*i+j*j)*CoordCoeff2
                // blur in distance to first local approximation
                // instead of blur in color space
                + dot(diffColorToGradient,diffColorToGradient)*LumCoeff2
                // blur in gradient space
                + dot( diffGradientX*diffGradientX + diffGradientY*diffGradientY , LUMWEIGHT )*GradCoeff2
                ));


            if( i == -RADIUS && j == -RADIUS ){
            	col = color*coeff;
            } else {
            	col += color*coeff;
            }

            sum += coeff;

        }
    }

    // no need for uncertainty map (mix to thisColor based on sum log value)
    // like in https://www.shadertoy.com/view/MlVGW3 ?
	col = col / sum;

	col = thisColor - 2.0 * (col - thisColor);

  gl_FragColor = col;
}
