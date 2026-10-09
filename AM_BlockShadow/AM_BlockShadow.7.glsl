#version 120

// BlockShadow pass 7: horizontal gaussian blur of the shadow.
// Blurs the shadow matte (R) and its premultiplied extrusion position (G).

uniform sampler2D adsk_results_pass4;
uniform float adsk_result_w, adsk_result_h, adsk_result_pixelratio;

uniform float softness;  // gaussian sigma in pixels

// Upper bound on kernel half-width in pixels.
const int MAX_RADIUS = 1024;

void main(void)
{
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 uv = gl_FragCoord.xy / res;
	float ratio = adsk_result_pixelratio > 0.0 ? adsk_result_pixelratio : 1.0;

	// Softness is in display pixels; convert to image pixels horizontally.
	float sigma = max(softness, 0.0) / ratio;
	if (sigma < 0.01) {
		gl_FragColor = texture2D(adsk_results_pass4, uv);
		return;
	}

	int radius = int(ceil(sigma * 3.0));
	float k = -0.5 / (sigma * sigma);
	vec2 texel = vec2(1.0 / res.x, 0.0);

	vec2 sum = texture2D(adsk_results_pass4, uv).rg;
	float total = 1.0;
	for (int i = 1; i < MAX_RADIUS; i++) {
		if (i > radius)
			break;
		float x = float(i);
		float w = exp(x * x * k);
		sum += w * (texture2D(adsk_results_pass4, uv + texel * x).rg
		          + texture2D(adsk_results_pass4, uv - texel * x).rg);
		total += 2.0 * w;
	}
	sum /= total;

	gl_FragColor = vec4(sum, 0.0, sum.r);
}
