#version 120

uniform sampler2D back, adsk_results_pass2;
uniform float adsk_result_w, adsk_result_h;
uniform float underlying_layer_low, underlying_layer_high, underlying_threshold_low, underlying_threshold_high, amount;
float adsk_getLuminance( in vec3 color );
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor );
uniform int blend_modes, logic_op_sel, LogicOp;

// uniform bool idarken,imultiply,icolorBurn,ilinearBurn,idarkerColor,ilighten,iscreen,icolorDodge,ilinearDodge,ilighterColor,ioverlay,isoftLight,ihardLight,ivividLight,ilinearLight,ipinLight,ihardMix,idifference,iexclusion,isubstract,idivide,ihue,icolor,isaturation,iluminosity;

vec3 normal( vec3 s, vec3 d )
{
	return s;
}

vec3 darken( vec3 s, vec3 d )
{
	return min(s,d);
}

vec3 multiply( vec3 s, vec3 d )
{
	return s*d;
}

vec3 colorBurn( vec3 s, vec3 d )
{
	return 1.0 - (1.0 - d) / s;
}

vec3 linearBurn( vec3 s, vec3 d )
{
	return s + d - 1.0;
}

vec3 darkerColor( vec3 s, vec3 d )
{
	return (s.x + s.y + s.z < d.x + d.y + d.z) ? s : d;
}

vec3 lighten( vec3 s, vec3 d )
{
	return max(s,d);
}

vec3 screen( vec3 s, vec3 d )
{
	return s + d - s * d;
}

vec3 colorDodge( vec3 s, vec3 d )
{
	return d / (1.0 - s);
}

vec3 linearDodge( vec3 s, vec3 d )
{
	return s + d;
}

vec3 lighterColor( vec3 s, vec3 d )
{
	return (s.x + s.y + s.z > d.x + d.y + d.z) ? s : d;
}

float overlay( float s, float d )
{
	return (d < 0.5) ? 2.0 * s * d : 1.0 - 2.0 * (1.0 - s) * (1.0 - d);
}

vec3 overlay( vec3 s, vec3 d )
{
	vec3 c;
	c.x = overlay(s.x,d.x);
	c.y = overlay(s.y,d.y);
	c.z = overlay(s.z,d.z);
	return c;
}

float softLight( float s, float d )
{
	return (s < 0.5) ? d - (1.0 - 2.0 * s) * d * (1.0 - d)
		: (d < 0.25) ? d + (2.0 * s - 1.0) * d * ((16.0 * d - 12.0) * d + 3.0)
					 : d + (2.0 * s - 1.0) * (sqrt(d) - d);
}

vec3 softLight( vec3 s, vec3 d )
{
	vec3 c;
	c.x = softLight(s.x,d.x);
	c.y = softLight(s.y,d.y);
	c.z = softLight(s.z,d.z);
	return c;
}

float hardLight( float s, float d )
{
	return (s < 0.5) ? 2.0 * s * d : 1.0 - 2.0 * (1.0 - s) * (1.0 - d);
}

vec3 hardLight( vec3 s, vec3 d )
{
	vec3 c;
	c.x = hardLight(s.x,d.x);
	c.y = hardLight(s.y,d.y);
	c.z = hardLight(s.z,d.z);
	return c;
}

float vividLight( float s, float d )
{
	return (s < 0.5) ? 1.0 - (1.0 - d) / (2.0 * s) : d / (2.0 * (1.0 - s));
}

vec3 vividLight( vec3 s, vec3 d )
{
	vec3 c;
	c.x = vividLight(s.x,d.x);
	c.y = vividLight(s.y,d.y);
	c.z = vividLight(s.z,d.z);
	return c;
}

vec3 linearLight( vec3 s, vec3 d )
{
	return 2.0 * s + d - 1.0;
}

float pinLight( float s, float d )
{
	return (2.0 * s - 1.0 > d) ? 2.0 * s - 1.0 : (s < 0.5 * d) ? 2.0 * s : d;
}

vec3 pinLight( vec3 s, vec3 d )
{
	vec3 c;
	c.x = pinLight(s.x,d.x);
	c.y = pinLight(s.y,d.y);
	c.z = pinLight(s.z,d.z);
	return c;
}

vec3 hardMix( vec3 s, vec3 d )
{
	return floor(s + d);
}

vec3 difference( vec3 s, vec3 d )
{
	return abs(d - s);
}

vec3 exclusion( vec3 s, vec3 d )
{
	return s + d - 2.0 * s * d;
}

vec3 subtract( vec3 s, vec3 d )
{
	return s - d;
}

vec3 divide( vec3 s, vec3 d )
{
	return s / d;
}

vec3 spotlightBlend( vec3 s, vec3 d )
{
	return d*s+d;
}

vec3 over( vec3 s, vec3 d, vec3 matte)
{
	vec3 c;
	c = (1.0-matte)*d;
	c = screen(s,c);
	return c;

}

//	rgb<-->hsv functions by Sam Hocevar
//	http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 rgb2hsv(vec3 c)
{
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 hue( vec3 s, vec3 d )
{
	d = rgb2hsv(d);
	d.x = rgb2hsv(s).x;
	return hsv2rgb(d);
}

vec3 color( vec3 s, vec3 d )
{
	s = rgb2hsv(s);
	s.z = rgb2hsv(d).z;
	return hsv2rgb(s);
}

vec3 saturation( vec3 s, vec3 d )
{
	d = rgb2hsv(d);
	d.y = rgb2hsv(s).y;
	return hsv2rgb(d);
}

vec3 luminosity( vec3 s, vec3 d )
{
	float dLum = dot(d, vec3(0.3, 0.59, 0.11));
	float sLum = dot(s, vec3(0.3, 0.59, 0.11));
	float lum = sLum - dLum;
	vec3 c = d + lum;
	float minC = min(min(c.x, c.y), c.z);
	float maxC = max(max(c.x, c.y), c.z);
	if(minC < 0.0) return sLum + ((c - sLum) * sLum) / (sLum - minC);
	else if(maxC > 1.0) return sLum + ((c - sLum) * (1.0 - sLum)) / (maxC - sLum);
	else return c;
}

void main()
{
   vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
   vec4 c = texture2D(adsk_results_pass2, uv);
   vec4 bg = texture2D(back, uv);
   float l = adsk_getLuminance( texture2D( back, uv ).rgb);

   // START underlying layer low slider
   float underlying_low = underlying_layer_low - underlying_threshold_low * 0.5;
   float l1 = min(max(l - underlying_low, 0.0) / (underlying_layer_low - underlying_low), 1.0);
   // END underlying layer low slider

   // START underlying layer high slider
   float underlying_high = underlying_layer_high - underlying_threshold_high * 0.5;
   float l2 = min(max(l - underlying_high, 0.0) / (underlying_layer_high - underlying_high), 1.0);
   l2 = 1.0 - l2;
   // END underlying layer high slider

   // combining the mattes
   float l3 = l1 * l2;
   l3 = l3 * c.a;

	 vec3 s = c.rgb;
	 vec3 d = bg.rgb;

	 if ( logic_op_sel == 0 )
	 {
		 if( LogicOp ==0)
		   	c.rgb = darken(s,d);
	   else if ( LogicOp == 1)
		    c.rgb = multiply(c.rgb,d);
	   else if ( LogicOp == 2)
		    c.rgb = colorBurn(s,d);
	   else if ( LogicOp == 3)
		    c.rgb = linearBurn(s,d);
	   else if ( LogicOp == 4)
		    c.rgb = darkerColor(s,d);
	   else if ( LogicOp == 5)
		   c.rgb = c.rgb;
	   else if ( LogicOp == 6)
		   c.rgb =  lighten(s,d);
	   else if ( LogicOp == 7)
		   c.rgb = screen(s,d);
	   else if ( LogicOp == 8)
		   c.rgb =  colorDodge(s,d);
	   else if ( LogicOp == 9)
		   c.rgb =  linearDodge(s,d);
	   else if ( LogicOp == 10)
		   c.rgb =  lighterColor(s,d);
	   else if ( LogicOp == 11)
		   c.rgb =  overlay(s,d);
	   else if ( LogicOp == 12)
		   c.rgb = softLight(s,d);
	   else if ( LogicOp == 13)
		   c.rgb =  hardLight(s,d);
	   else if ( LogicOp == 14)
		   c.rgb =  vividLight(s,d);
	   else if ( LogicOp == 15)
		   c.rgb =  linearLight(s,d);
	   else if ( LogicOp == 16)
		   c.rgb =  pinLight(s,d);
	   else if ( LogicOp == 17)
		   c.rgb =  hardMix(s,d);
	   else if ( LogicOp == 18)
		   c.rgb =  difference(s,d);
	   else if ( LogicOp == 19)
		   c.rgb =  exclusion(s,d);
	   else if ( LogicOp == 20)
		   c.rgb = subtract(s,d);
	   else if ( LogicOp == 21)
		   c.rgb = divide(s,d);
	   else if ( LogicOp == 22)
		   c.rgb = hue(s,d);
	   else if ( LogicOp == 23)
		   c.rgb =  saturation(s,d);
	   else if ( LogicOp == 24)
		   c.rgb = color(s,d);
	   else if ( LogicOp == 25)
		   c.rgb =  luminosity(s,d);
	   else if ( LogicOp == 26)
		   c.rgb =  spotlightBlend(s,d);
	   else if ( LogicOp == 27)
		   c.rgb = normal(s,d);
	   else if ( LogicOp == 28)
		   c.rgb = over(s,d, vec3(l3));

			 if ( LogicOp == 28)
				c = c;
			 else
				c.rgb = vec3(l3 * c.rgb + (1.0 - l3) * bg.rgb);
	 }

	 else
	 {
		 c = adsk_getBlendedValue(blend_modes, bg, c);
		 c.rgb = vec3(l3 * c.rgb + (1.0 - l3) * bg.rgb);
	 }

	 c.rgb = mix(bg.rgb, c.rgb, amount);

   gl_FragColor = vec4(c.rgb, l3);
}
