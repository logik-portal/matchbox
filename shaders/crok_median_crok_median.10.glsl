#version 120
// based on https://www.shadertoy.com/view/MtcSzH by ttoinou
uniform sampler2D adsk_results_pass7, adsk_results_pass8, adsk_results_pass9;

uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform int amount; // 12
uniform float Detail; // 8
uniform int num_iter;

// my take on Trilateral Filtering
// http://dl.acm.org/citation.cfm?id=882431

// Upgrading Bilateral Blur with Gradient
// https://www.shadertoy.com/view/MlVGW3
//#define amount     (12)
#define DIAMETER   (2*amount+1)

// bigger theses coeff the more we take into account the space concerned
// shouldn't need to change it
// close to 0 => square-shaped
#define COORDCOEFF (1.41)

// if theses two == 0. => filter is a gaussian blur
// the closer to zero the blurier
// the bigger the more selective
//#define Detail   (8.)
#define GRADCOEFF  (1.)
#define GRADIENT_RADIUS (1)

// see line 84
// not confident in my calculus in buffB & buffC
#define LUMPLANECORRECTION (1.)
#define LUMWEIGHT    (vec4(0.2126,0.7152,0.0722,0.3333))
#define GRADIENT_RADIUSf float(GRADIENT_RADIUS)
#define GRADIENT_RADIUSi22f (4.)
#define viewport(x) ( (x) /res.xy)

void main()
{
	vec2 uv = viewport(gl_FragCoord.xy);
	vec2 uv2 = gl_FragCoord.xy / res;
  vec4 thisColor = texture2D(adsk_results_pass7,uv);
  vec4 thisGradX = texture2D(adsk_results_pass8,uv);
  vec4 thisGradY = texture2D(adsk_results_pass9,uv);

  vec4 c = vec4(0.);
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
  float LumCoeff2 = Detail*Detail;
  float CoordCoeff2 = COORDCOEFF*COORDCOEFF/float(amount*amount);

  for( int i = -amount ; i <= amount ; i++ ){
  	for( int j = -amount ; j <= amount ; j++ ){
      pos = viewport(gl_FragCoord.xy+vec2(i,j));
      color = texture2D(adsk_results_pass7,pos);
    	gradX = texture2D(adsk_results_pass8,pos);
      gradY = texture2D(adsk_results_pass9,pos);
    	diffGradientX = thisGradX - gradX;
      diffGradientY = thisGradY - gradY;
      diffColorToGradient = thisColor - color
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
      if( i == -amount && j == -amount ){
      	c = color*coeff;
        } else {
      	c += color*coeff;
      	}
        sum += coeff;
        }
    }
	c = c / sum;
	gl_FragColor = vec4(c.rgb, 1.0);
}
