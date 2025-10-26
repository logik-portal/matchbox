#version 120
// uncompositing
// with huge help from Erwan Leroy

uniform sampler2D front, back, matte;
uniform float adsk_result_w, adsk_result_h;
uniform float gamma;
uniform float gain;
uniform int i_colorspace;
uniform int modus;

vec4 rem_gamma( vec4 c )
{
    return pow( c, vec4(gamma));
}

vec4 srgb2lin(vec4 col)
{
    if (col.r >= 0.0) {
         col.r = pow((col.r +.055)/ 1.055, 2.4);
    }
    if (col.g >= 0.0) {
         col.g = pow((col.g +.055)/ 1.055, 2.4);
    }
    if (col.b >= 0.0) {
         col.b = pow((col.b +.055)/ 1.055, 2.4);
    }
    return col;
}

vec4 do_colorspace(vec4 front)
{
	if (i_colorspace == 0) {
		//linear
		front = front;
		}
	else if (i_colorspace == 1) {
		front = srgb2lin(front);
    }
    else {
      front = rem_gamma(front);
    }
    return front;
}

void main()
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );

    vec4 f = texture2D( front, uv );
    vec4 b = texture2D( back, uv);
		vec4 m = texture2D( matte, uv);
		vec4 c = vec4(0.0);

		if ( modus == 0 )
		{
			// adjust colourspace
			f = do_colorspace(f);
      b = do_colorspace(b);
      if (i_colorspace != 1)
        m = do_colorspace(m);

			// Undo a blend operation:
			c = f-b*(1.0-m);
		}
		else
		{
			// remove logo from BG
			//Background = Result / (1 – AlphaOfA) - Foreground
			c = (b - f) / (1.0 - m * gain);
		}
		gl_FragColor = vec4(c.rgb, m.r);
}
