#version 120

// BlockShadow pass 8: vertical gaussian blur of the shadow, then comp the
// layers. Back to front: silhouette outline, shadow, fill outline, fill.

uniform sampler2D adsk_results_pass1;  // rgb = premultiplied fill, a = fill matte
uniform sampler2D adsk_results_pass3;  // r = distance to the fill
uniform sampler2D adsk_results_pass4;  // r = hard shadow matte
uniform sampler2D adsk_results_pass6;  // r = distance to the silhouette
uniform sampler2D adsk_results_pass7;  // horizontally blurred shadow
uniform sampler2D shadowFill;          // optional gradient/texture for the shadow
uniform float adsk_result_w, adsk_result_h;

uniform float softness;  // gaussian sigma in pixels
uniform vec3 shadowColor;
uniform bool useShadowFill;
uniform bool shadeExtrusion;
uniform vec3 farColor;
uniform float farOpacity;
uniform float shadowOpacity;  // 0 = invisible, 1 = solid
uniform bool shadowOnly;
uniform int outlineMode;      // 0 = off, 1 = fill, 2 = silhouette, 3 = both
uniform float outlineWidth;   // pixels
uniform vec3 outlineColor;

// Upper bound on kernel half-width in pixels.
const int MAX_RADIUS = 1024;

// Coverage of an outline of the given width at distance d from a shape.
float outlineCoverage(float d)
{
	return clamp(outlineWidth + 0.5 - d, 0.0, 1.0);
}

void main(void)
{
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 uv = gl_FragCoord.xy / res;

	// Vertical blur of the shadow matte (R) and its extrusion position (G).
	float sigma = max(softness, 0.0);
	vec2 shadow = texture2D(adsk_results_pass7, uv).rg;
	if (sigma >= 0.01) {
		int radius = int(ceil(sigma * 3.0));
		float k = -0.5 / (sigma * sigma);
		vec2 texel = vec2(0.0, 1.0 / res.y);

		float total = 1.0;
		for (int i = 1; i < MAX_RADIUS; i++) {
			if (i > radius)
				break;
			float y = float(i);
			float w = exp(y * y * k);
			shadow += w * (texture2D(adsk_results_pass7, uv + texel * y).rg
			             + texture2D(adsk_results_pass7, uv - texel * y).rg);
			total += 2.0 * w;
		}
		shadow /= total;
	}

	float shadowA = clamp(shadow.r, 0.0, 1.0);
	float along = shadow.r > 1e-5 ? clamp(shadow.g / shadow.r, 0.0, 1.0) : 0.0;

	vec3 shadowRGB = useShadowFill ? texture2D(shadowFill, uv).rgb : shadowColor;
	if (shadeExtrusion) {
		shadowRGB = mix(shadowRGB, farColor, along);
		shadowA *= mix(1.0, clamp(farOpacity, 0.0, 1.0), along);
	}
	shadowA *= clamp(shadowOpacity, 0.0, 1.0);

	vec4 fill = texture2D(adsk_results_pass1, uv);
	float fillA = fill.a;

	// Outlines are rings around the hard shapes, so they never show through
	// a see-through shadow or fill.
	float fillLine = 0.0;
	float shapeLine = 0.0;
	if (outlineMode != 0 && outlineWidth > 0.0) {
		float shapeA = max(fillA, texture2D(adsk_results_pass4, uv).r);
		if (outlineMode == 1 || outlineMode == 3)
			fillLine = clamp(outlineCoverage(texture2D(adsk_results_pass3, uv).r) - fillA, 0.0, 1.0);
		if (outlineMode == 2 || outlineMode == 3)
			shapeLine = clamp(outlineCoverage(texture2D(adsk_results_pass6, uv).r) - shapeA, 0.0, 1.0);
	}

	// Comp back to front, premultiplied.
	vec3 rgb = outlineColor * shapeLine;
	float alpha = shapeLine;

	rgb = shadowRGB * shadowA + rgb * (1.0 - shadowA);
	alpha = shadowA + alpha * (1.0 - shadowA);

	// Output just the shadow (and its outline), without holding it out by the
	// fill, so the fill can be comped back over it later.
	if (shadowOnly) {
		gl_FragColor = vec4(rgb, alpha);
		return;
	}

	rgb = outlineColor * fillLine + rgb * (1.0 - fillLine);
	alpha = fillLine + alpha * (1.0 - fillLine);

	rgb = fill.rgb + rgb * (1.0 - fillA);
	alpha = fillA + alpha * (1.0 - fillA);

	gl_FragColor = vec4(rgb, alpha);
}
