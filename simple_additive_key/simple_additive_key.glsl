// version 120 is to make it work on Mac
#version 120

//Image resolution
uniform float adsk_result_w, adsk_result_h;

// Define Inputs
uniform sampler2D front, back, matte;

// Define Uniform Variables (that we will be able to control in the user interface)
uniform vec3 reference;
uniform float mix_highs;
uniform float mix_darks;
uniform float desat_highs;
uniform float desat_darks;
uniform int bg_only;
uniform bool neg_clamp;

// Define some functions if needed
vec3 desaturate(vec3 color, float amount)
{
	vec3 gray = vec3(dot(vec3(0.2126,0.7152,0.0722), color));
	return vec3(mix(color, gray, amount));
}

// Main loop (Where most of the magic happens)
void main(void)
{
	//The next line is required for the shader to work. It tells the shader which pixel we're now working on.
        vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	
	//Get our inputs (notice it refers to the previous line "uv" to indicate which pixel we're looking at)
	vec3 f = texture2D(front, uv).rgb;
	vec3 b = texture2D(back, uv).rgb;
	vec3 m = texture2D(matte, uv).rgb;

	// I'm also going to recall my uniform "reference" as a faster way to type "r"
	vec3 r = reference;

	// subtract operation (front minus reference)
	vec3 sub = f - r;
	
	// Max 0.0 to get all the positives
	vec3 highs = max(sub, 0.0);
	// And min for the negatives
	vec3 darks = min(sub, 0.0);

	//Give an option to desaturate the highlights and the darks separately, each with a SLIDER (0 to 1)
	highs = desaturate(highs, desat_highs);
	darks = desaturate(darks, desat_darks);

	//Finally, let them decide how much of the darks and highlights they want to add, there are multiple ways to do that, the easiest I think is to put a simple multiplier, 0 would kill the values, 1 would be normal, above 1 would make it more intense. If you want to go overkill you could separate that in R,G and B gain.
	highs = highs * mix_highs;
	darks = darks * mix_darks;

	//Now we add both the darks and highlights to the BG plate (since the darks are negative values, it gets darker)
	b = b + highs + darks;
	// risk of negative values, maybe need a neg clamp
	if (neg_clamp == true) {
		b = max(b, 0.0);
	}

		
	// Blend all together for the final comp on top of new back.
	vec3 result = vec3(m * f + (1.0 - m) * b);

	//Output the final result.
	if (bg_only == 1) {
		//If the user chose to output the BG only, output the BG:
		gl_FragColor = vec4(b, m);
	} else {
		//else Output the result
		gl_FragColor = vec4(result, m);
	}
}
