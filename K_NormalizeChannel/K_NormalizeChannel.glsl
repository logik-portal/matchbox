//
// K_NormalizeChannel v1.1
// Shader written by:   Kyle Obley (kyle.obley@gmail.com)
//

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
uniform float minimum, maximum;
uniform int channel;

void main()
{
   vec2 uv = gl_FragCoord.xy / vec2 (adsk_result_w, adsk_result_h);
   vec4 col = texture2D(front, uv);

	if ( channel == 1 )
	{
		col = col.rrrr;
	}

	else if ( channel == 2 )
	{
		col = col.gggg;
	}

	else if ( channel == 3 )
	{
		col = col.bbbb;
	}

	col = min(max(col - vec4(minimum), vec4(0.0)) / (vec4(maximum) - vec4(minimum)), 1.0);
	gl_FragColor = vec4(col);
}