uniform float adsk_result_w;
uniform float adsk_result_h;
uniform sampler2D front;
uniform float amount;
uniform int type;


void main (){
	// Standard Autodesk Stuff
	vec3 source = texture2D(front, gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h )).rgb;

	vec3 result 		= source;
	vec3 suppressed 	= source;

	if(type == 0)
		suppressed.g 		= min((source.r+source.b)*0.5, suppressed.g);	
	else if(type == 1)
		suppressed.b 		= min((source.g+source.r)*0.5, suppressed.b);
	else if(type == 2)
		suppressed.r 		= min((source.g+source.b)*0.5, suppressed.r);	

	result				= mix( source, suppressed, amount );

	gl_FragColor 	= 	vec4( result, 1.0);
}




