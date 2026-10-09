#version 120

// BlockShadow pass 6: distance to the silhouette (fill + shadow), vertical half.
//
// Combines the per-row distances from pass 5 into a Euclidean distance.
//
// Output R : distance to the silhouette, in display pixels

uniform sampler2D adsk_results_pass5;
uniform float adsk_result_w, adsk_result_h;

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
	vec2 px = gl_FragCoord.xy;

	int radius = int(ceil(outlineWidth + 1.0));

	float d = FAR;
	for (int j = 0; j < 2 * MAX_RADIUS + 1; j++) {
		int i = j - radius;
		if (i > radius)
			break;
		vec2 uv = (px + vec2(0.0, float(i))) / res;
		if (uv.y < 0.0 || uv.y > 1.0)
			continue;

		// R = horizontal distance to that row's nearest pixel, G = its edge
		// offset. The edge offset applies along the full 2D direction, so
		// coverage counts vertically as well as horizontally.
		vec2 h = texture2D(adsk_results_pass5, uv).rg;
		float dy = abs(float(i));
		if (h.r < FAR)
			d = min(d, sqrt(h.r * h.r + dy * dy) + h.g);
	}

	gl_FragColor = vec4(d, 0.0, 0.0, 1.0);
}
