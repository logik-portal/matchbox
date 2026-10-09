#version 120

// BlockShadow pass 4: extrude the matte into a hard block shadow, then cut the
// Gap out around the fill.
//
// Output R : shadow matte
// Output G : shadow matte * how far along the extrusion this pixel is
//            (0 = near the fill, 1 = far end), premultiplied so it blurs cleanly
//
// Distances are measured in display pixels (pixel aspect ratio applied), so the
// shadow keeps its angle on non-square pixel formats.

uniform sampler2D adsk_results_pass1;  // a = fill matte
uniform sampler2D adsk_results_pass3;  // r = distance to the fill
uniform float adsk_result_w, adsk_result_h, adsk_result_pixelratio;

uniform float angle;             // degrees, 0 = right, counter-clockwise
uniform float shadowLength;      // pixels
uniform float shadowGap;         // pixels between the fill and the shadow
uniform bool perspective;
uniform vec2 vanishingPoint;     // 0-1 frame coordinates
uniform float perspectiveDepth;  // 0-1, fraction of the way to the vanishing point

// Upper bound on extrusion samples (one per pixel of length).
const int MAX_STEPS = 4096;

vec2 res;

float sampleMatte(vec2 px)
{
	// Treat anything outside the frame as empty so edges don't smear inward.
	vec2 uv = px / res;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
		return 0.0;
	return texture2D(adsk_results_pass1, uv).a;
}

void main(void)
{
	res = vec2(adsk_result_w, adsk_result_h);
	float ratio = adsk_result_pixelratio > 0.0 ? adsk_result_pixelratio : 1.0;
	vec2 px = gl_FragCoord.xy;
	float gap = max(shadowGap, 0.0);

	// March from this pixel towards the shape that casts onto it, in display
	// pixels: dir is the march direction and t runs from 1 to tEnd.
	vec2 dir;
	float tEnd;
	float distToVP = 0.0;
	float depth = clamp(perspectiveDepth, 0.0, 0.99);

	if (perspective) {
		vec2 vp = vanishingPoint * res;
		vec2 away = vec2((px.x - vp.x) * ratio, px.y - vp.y);
		distToVP = length(away);
		if (distToVP < 0.5 || depth <= 0.0) {
			gl_FragColor = vec4(0.0);
			return;
		}
		// Shapes extrude towards the vanishing point, so the caster lies further
		// away from it. A point at distance R reaches R * (1 - depth), so this
		// pixel can be covered by points out to distToVP / (1 - depth).
		dir = away / distToVP;
		tEnd = distToVP * depth / (1.0 - depth);
	} else {
		float rad = radians(angle);
		dir = -vec2(cos(rad), sin(rad));
		// Extend by the gap so the visible shadow is still Length long.
		tEnd = max(shadowLength, 0.0) + gap;
	}

	int steps = int(ceil(tEnd));
	vec2 stepPx = vec2(dir.x / ratio, dir.y);

	float shadowA = 0.0;
	float hitU = 0.0;
	// Start one pixel out, never at this pixel itself, so the shadow sits
	// behind the fill without fringing its edges.
	for (int i = 1; i < MAX_STEPS; i++) {
		if (i > steps || shadowA >= 1.0)
			break;
		float t = min(float(i), tEnd);

		float m = sampleMatte(px + stepPx * t);
		if (m > shadowA) {
			shadowA = m;
			// Position along the extrusion of the nearest caster, 0-1.
			if (perspective)
				hitU = (t / (distToVP + t)) / depth;
			else
				hitU = shadowLength > 0.0 ? (t - gap) / shadowLength : 0.0;
		}
	}

	// Cut the shadow back to Gap pixels away from the fill.
	if (gap > 0.0) {
		float d = texture2D(adsk_results_pass3, px / res).r;
		shadowA *= 1.0 - clamp(gap + 0.5 - d, 0.0, 1.0);
	}

	gl_FragColor = vec4(shadowA, shadowA * clamp(hitU, 0.0, 1.0), 0.0, shadowA);
}
