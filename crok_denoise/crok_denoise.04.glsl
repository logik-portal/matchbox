#version 120
// based on https://www.shadertoy.com/view/MtcSzH by ttoinou
uniform sampler2D adsk_results_pass1, adsk_results_pass2, adsk_results_pass3, matte;

uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform int RADIUS; // 12
uniform float LUMCOEFF; // 8

// my take on Trilateral Filtering
// http://dl.acm.org/citation.cfm?id=882431

// Upgrading Bilateral Blur with Gradient
// https://www.shadertoy.com/view/MlVGW3
//#define RADIUS     (12)
#define DIAMETER   (2*RADIUS+1)

// bigger theses coeff the more we take into account the space concerned
// shouldn't need to change it
// close to 0 => square-shaped
#define COORDCOEFF (1.41)

// if theses two == 0. => filter is a gaussian blur
// the closer to zero the blurier
// the bigger the more selective
//#define LUMCOEFF   (8.)
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
	float m = texture2D(matte, uv2).r;
  vec4 thisColor = texture2D(adsk_results_pass1,uv);
  vec4 thisGradX = texture2D(adsk_results_pass2,uv);
  vec4 thisGradY = texture2D(adsk_results_pass3,uv);

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
  float LumCoeff2 = LUMCOEFF*LUMCOEFF;
  float CoordCoeff2 = COORDCOEFF*COORDCOEFF/float(RADIUS*RADIUS);

  for( int i = -RADIUS ; i <= RADIUS ; i++ ){
  	for( int j = -RADIUS ; j <= RADIUS ; j++ ){
      pos = viewport(gl_FragCoord.xy+vec2(i,j));
      color = texture2D(adsk_results_pass1,pos);
      gradX = texture2D(adsk_results_pass2,pos);
      gradY = texture2D(adsk_results_pass3,pos);
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
      if( i == -RADIUS && j == -RADIUS ){
      	c = color*coeff;
        } else {
      	c += color*coeff;
      	}
        sum += coeff;
        }
    }

	c = c / sum;
	c = vec4(m * c + (1.0 - m) * thisColor);
	gl_FragColor = vec4(c.rgb, m);
}
