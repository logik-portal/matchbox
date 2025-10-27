uniform float adsk_result_w;
uniform float adsk_result_h;
uniform sampler2D front;
uniform sampler2D matte;
uniform vec3 s_whitePoint;
uniform bool premultiplied;
uniform float temp, tint, t_saturation;
uniform float offset, gamma, multiply;
uniform vec3 RGBOffset, RGBGamma, RGBMultiply;

const float ONE_THIRD  = 0.3333333333333333333;
const float TWO_THIRDS = 0.6666666666666666667;


void main (){
	// Standard Autodesk Stuff
	vec3 	source 	= texture2D(front, gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h )).rgb;
	float 	alpha	= texture2D(matte, gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h )).r;
	
	vec3 result = source;
	
	if(premultiplied)
		if (alpha !=0.0)
			result = source / vec3(alpha);
		else
			result = vec3(0.0);

	// White Balance Pre (adjust tint & temp of white point)
	vec3 x_whitePoint = s_whitePoint;
	vec3 t_whitepoint = vec3(	x_whitePoint.r -=(tint*ONE_THIRD)+(temp*0.5),
								x_whitePoint.g +=(tint*TWO_THIRDS),
								x_whitePoint.b -=(tint*ONE_THIRD)-(temp*0.5));
	

	// Perform Averaged White Balance of Source
	result = vec3(	result.r / (t_whitepoint.r/((t_whitepoint.r + t_whitepoint.g + t_whitepoint.b)*ONE_THIRD)),
					result.g / (t_whitepoint.g/((t_whitepoint.r + t_whitepoint.g + t_whitepoint.b)*ONE_THIRD)),
					result.b / (t_whitepoint.b/((t_whitepoint.r + t_whitepoint.g + t_whitepoint.b)*ONE_THIRD)) );

	// offset
	result += vec3(offset);
	result += RGBOffset;
	// multiply
	result *= vec3(multiply);
	result *= RGBMultiply;

	// Gamma - Apparently this is not technically a scene linear gamma adjustment 
	// however this is how Nuke does it sooooo....

	result = pow( abs(result), 1.0/vec3(gamma)) * sign(result);
	result = vec3( 	pow( abs(result.r), 1.0/RGBGamma.r) * sign(result.r),
					pow( abs(result.g), 1.0/RGBGamma.g) * sign(result.g),
					pow( abs(result.b), 1.0/RGBGamma.b) * sign(result.b));

	// Saturation
	float luma = (0.2126 * result.r) + (0.7152 * result.g) + (0.0722 * result.b);
	result.r = luma + t_saturation * (result.r - luma);
	result.g = luma + t_saturation * (result.g - luma);
	result.b = luma + t_saturation * (result.b - luma);

	if(premultiplied)
		gl_FragColor = 	vec4( result*vec3(alpha), alpha);
	else
		gl_FragColor = 	vec4( result, alpha);
}


