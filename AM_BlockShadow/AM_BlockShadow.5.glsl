#version 120

// BlockShadow pass 5: distance to the silhouette (fill + shadow), horizontal
// half. Only used by the Silhouette outline.
//
// Output R : horizontal distance to the nearest silhouette pixel on this row
// Output G : that pixel's edge offset, 0.5 - coverage (see pass 6)

uniform sampler2D adsk_results_pass1;  // a = fill matte
uniform sampler2D adsk_results_pass4;  // r = hard shadow matte
uniform float adsk_result_w, adsk_result_h, adsk_result_pixelratio;

uniform int outlineMode;    // 0 = off, 1 = fill, 2 = silhouette, 3 = both
uniform float outlineWidth; // pixels

const int MAX_RADIUS = 1024;
const float FAR = 10000.0;

void main(void)
{
	bool shapeOutline = outlineMode == 2 || outlineMode == 3;
	if (!shapeOutline || outlineWidth <= 0.0) {
		gl_FragColor = vec4(FAR);
		return;
	}

	vec2 res = vec2(adsk_result_w, adsk_result_h);
	float ratio = adsk_result_pixelratio > 0.0 ? adsk_result_pixelratio : 1.0;
	vec2 px = gl_FragCoord.xy;

	int radius = int(ceil((outlineWidth + 1.0) / ratio));

	float best = FAR;
	float bestDx = FAR;
	float bestEdge = 0.0;
	for (int j = 0; j < 2 * MAX_RADIUS + 1; j++) {
		int i = j - radius;
		if (i > radius)
			break;
		vec2 uv = (px + vec2(float(i), 0.0)) / res;
		if (uv.x < 0.0 || uv.x > 1.0)
			continue;

		// A pixel's edge sits (0.5 - coverage) pixels from its centre, so
		// partly covered pixels place the edge between pixels. This keeps the
		// distance smooth along the edge, which anti-aliases the outline.
		float a = max(texture2D(adsk_results_pass1, uv).a, texture2D(adsk_results_pass4, uv).r);
		if (a > 0.0) {
			float dx = abs(float(i)) * ratio;
			float edge = 0.5 - a;
			if (dx + edge < best) {
				best = dx + edge;
				bestDx = dx;
				bestEdge = edge;
			}
		}
	}

	gl_FragColor = vec4(bestDx, bestEdge, 0.0, 1.0);
}
