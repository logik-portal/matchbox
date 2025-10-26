uniform float adsk_result_w;
uniform float adsk_result_h;
uniform sampler2D front;
uniform sampler2D back;
uniform sampler2D matte;
uniform bool premultiplied;
uniform vec3 s_whitePoint, s_blackPoint;
uniform vec3 t_whitePoint, t_blackPoint;

void main (){
	// standard autodesk stuff
	vec3 source = texture2D(front, gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h )).rgb;
	vec3 target = texture2D(back, gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h )).rgb;
	float alpha	= texture2D(matte, gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h )).r;

	vec3 result = vec3(1.0);

	if(premultiplied)
		if (alpha !=0.0)
			result = source / vec3(alpha);
		else
			result = vec3(0.0);

	// White Balance Source
	result 			= vec3(	(source - s_blackPoint) / s_whitePoint);
	
	// White Balance to Target Values
	result 			= vec3( (result * t_whitePoint) + t_blackPoint);

	if(premultiplied)
		gl_FragColor = 	vec4( result*vec3(alpha), alpha);
	else
		gl_FragColor = 	vec4( result, alpha);
}
