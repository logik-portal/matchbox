#version 120

// BlockShadow Matchbox
// Extrudes the matte along an angle to build a solid "block" style drop shadow,
// softens it with a gaussian blur, then comps the fill (colour or front) over it.
//
// Output RGB   : fill over shadow, premultiplied
// Output Alpha : combined fill + shadow matte
//
// Pass 1: build the premultiplied fill and carry the matte in alpha.
// Later passes read the fill and matte from this result.

uniform sampler2D front;
uniform sampler2D matte;
uniform float adsk_result_w, adsk_result_h;

uniform vec3 fillColor;
uniform bool useFillColor;
uniform bool frontPremultiplied;

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);

	float fillA = clamp(texture2D(matte, uv).r, 0.0, 1.0);

	// A premultiplied Front already carries the matte, so don't apply it twice.
	vec3 fillPremult;
	if (useFillColor)
		fillPremult = fillColor * fillA;
	else if (frontPremultiplied)
		fillPremult = texture2D(front, uv).rgb;
	else
		fillPremult = texture2D(front, uv).rgb * fillA;

	gl_FragColor = vec4(fillPremult, fillA);
}
