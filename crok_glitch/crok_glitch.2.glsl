// Pass 1: make the vectors
// lewis@lewissaunders.com
// TODO:
//  o Pre-blur input in case of kinks?

uniform sampler2D adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h;


void main() {
	vec2 xy = gl_FragCoord.xy;

	// Factor to convert pixels to [0,1] texture coords
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);
	vec2 d = vec2(0.0);

	d = texture2D(adsk_results_pass1, xy * px).xy;
	gl_FragColor = vec4(d.x, d.y, 0.0, 1.0);
}
