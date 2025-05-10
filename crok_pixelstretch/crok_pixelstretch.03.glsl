#version 120
// based on https://www.shadertoy.com/view/XdX3zj

uniform sampler2D front, adsk_results_pass2, strength, matte;
uniform float adsk_result_w, adsk_result_h, adsk_time;
uniform int spread_type;
uniform float disp;
uniform float matte_gamma;
uniform int type;
vec2 res = vec2(adsk_result_w, adsk_result_h);
float iGlobalTime = adsk_time *0.05;

float maxLOD = 6.0;
#define EPS .5e-2
float level = 0.0;

float gamma(float src, float value)
{
  return pow( max( 0.0, src ), 1.0 / value );
}

vec3 mytexg(vec2 uv)
{
	float matte_col = texture2D(adsk_results_pass2, uv).r;
	matte_col = gamma(matte_col, matte_gamma);
	return vec3(matte_col);
}

void main( void )
{
	vec2 uv = ( gl_FragCoord.xy / res);
	float s = texture2D(strength, uv).r;
	float mode = 0.61;
	if ( disp > 0.0 )
		mode = 0.81;

	level = maxLOD*uv.x*uv.x;

   if(abs(mode-.5)>.1)
	 {
		vec3 tex,texx,texy,texmx,texmy;
		vec2 uvx,uvy,uvmx,uvmy;
		uvx  = uv+vec2(EPS,0.);
		uvy  = uv+vec2(0.,EPS);
		uvmx = uv-vec2(EPS,0.);
		uvmy = uv-vec2(0.,EPS);

		vec2 grad = vec2(0.0);
		float g = 1.0;
		bool isin = (mode>.5);
		float sgn = sign(abs(mode-.5)-.3);
 		for (int i=0; i<abs(disp * s); i++)
		{
			tex = mytexg(uv);
			if (isin)
			{
				uvx  = uv+vec2(EPS,0.);
				uvy  = uv+vec2(0.,EPS);
				uvmx = uv-vec2(EPS,0.);
				uvmy = uv-vec2(0.,EPS);
			}
			texx  = mytexg(uvx );
			texy  = mytexg(uvy );
			texmx = mytexg(uvmx);
			texmy = mytexg(uvmy);
			grad  = sgn*vec2(texx.x-texmx.x,texy.x-texmy.x);

			uv    += EPS*grad;
			uvx.x += EPS*grad.x;
			uvy.y += EPS*grad.y;
			uvmx.x -= EPS*grad.x;
			uvmx.y -= EPS*grad.y;
			}
	}
	vec3 col = texture2D(front, uv).rgb;
	float m = texture2D(matte, uv).r;

	gl_FragColor = vec4(col, m);
}
