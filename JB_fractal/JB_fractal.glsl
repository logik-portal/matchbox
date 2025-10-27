uniform float adsk_result_w;
uniform float adsk_result_h;

uniform float steps;
uniform float wx;
uniform float wy;
uniform int number;
uniform float adsk_time;
uniform vec2 ratio;
uniform vec2 positionB;
uniform float algo;
uniform vec3 color;


void main(void)
{
		
	vec2 w = vec2(wx,wy);
	vec2 st0;
	st0.x = gl_FragCoord.x / adsk_result_w;
	st0.y = gl_FragCoord.y / adsk_result_h;
	w.x = st0.x;
	w.y = st0.y;

	float f = 1.0;
	float g = f;
	float t = steps;
	
	vec2 p = vec2((ratio.x*st0.x-positionB.x),(ratio.y*st0.y-positionB.y));
	vec2 z = p;
	vec2 k = vec2(cos(t*algo),sin(algo*t));

	
	for( int i=0; i<number; i++ ) 
	{
				   
		z = vec2( z.x*z.x-z.x*z.y, z.x/z.y ) - p*k;
		f = min( f, abs(dot(z-p,z-k) ));
		g = min( g, dot(z,z));
	}
	
	f = log(f)/9.;
	vec4 c;
	c = abs(vec4(color.r*f,color.g*f,color.b*f,f));
	gl_FragColor = c;
}
