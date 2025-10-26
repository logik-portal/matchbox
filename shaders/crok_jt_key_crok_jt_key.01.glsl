#version 120
// DESPILL pass by John Ashby
uniform float adsk_result_w;
uniform float adsk_result_h;
uniform sampler2D front, matte, ext_despill;
uniform float amount, gain_amount;
uniform int type;
uniform	bool use_external_despilled_fg;

void main (){
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
	vec3 source = texture2D(front, uv).rgb;
	vec3 ex_s = texture2D(ext_despill, uv).rgb;
	float m = texture2D(matte, uv).r;

	vec3 result 		= source;
	vec3 suppressed 	= source;

	if ( use_external_despilled_fg )
	 	result = ex_s;

	else {
		if(type == 0)
			suppressed.g 		= min((source.r+source.b)*0.5, suppressed.g);
		else if(type == 1)
			suppressed.b 		= min((source.g+source.r)*0.5, suppressed.b);
		else if(type == 2)
			suppressed.r 		= min((source.g+source.b)*0.5, suppressed.r);

		result				= mix( source, suppressed, amount );

	}


	gl_FragColor 	= 	vec4( result, m);
}
