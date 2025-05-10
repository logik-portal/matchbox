// Pass 2: do the displace
// TODO:
//  o Diffuse samples out along/around path direction?
// lewis@lewissaunders.com

uniform sampler2D front, adsk_results_pass2;
uniform float adsk_result_w, adsk_result_h, blength, maxlength, sidestep;
uniform vec2 offset;
uniform int samples;
uniform bool radial, fadeout, fadein;

void main() {
	vec2 xy = gl_FragCoord.xy;

	// Factor to convert pixels to [0,1] texture coords
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	// Get vectors from previous pass
	vec2 d = texture2D(adsk_results_pass2, xy * px).xy;

	float sam = float(samples);

	vec4 acc = vec4(0.0);
	xy = gl_FragCoord.xy;
	// Starting point for this sample
	float dist = 0.0;
	// Walk along path by sampling vector image, moving, sampling, moving...
	for(float i = 0.0; i < sam; i++) {
		d = texture2D(adsk_results_pass2, xy * px).xy;
		if(length(d) == 0.0) {
		// No gradient at this point in the map, early out
		break;
		}
	xy += d * (blength/sam) + blength * sidestep/1000.0 * vec2(-d.y, d.x) + (blength/32.0) * offset;
	dist += length(d * (blength/sam));
	}
	// Sample front image where our walk ended up
	acc.rgb += texture2D(front, xy * px).rgb;
	// Length we've travelled to the matte output
	acc.a += dist * (blength/32.0);

	if(fadeout) {
		acc.rgb *= 1.0 - smoothstep(0.0, 1.0, abs(acc.a/(maxlength*blength+0.0001)));
	}
	if(fadein) {
		acc.rgb *= smoothstep(0.0, 1.0, abs(acc.a/(maxlength*blength)));
	}

	gl_FragColor = acc;
}
