#version 120

// Change the folling 4 lines to suite
#define INPUT adsk_results_pass2
//#define VERTICAL
//#define STRENGTH_CHANNEL
#define CENTER vec2(.5)

float   adsk_getLuminance( vec3 rgb );

#define ratio adsk_result_frameratio
#define PI 3.141592653589793238462643383279502884197969

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel  = vec2(1.0) / res;

uniform sampler2D INPUT;

#ifdef STRENGTH_CHANNEL
	uniform sampler2D Strength;
#endif

uniform int blur_type;
uniform float blur_amount;
uniform vec2 direction;
uniform bool use_angle;
uniform float angle;
uniform bool strength_are_vectors;
uniform bool blur_vectors;

#ifdef VERTICAL
	uniform float v_bias;
	float bias = v_bias;
	vec2 dir = vec2(0.0, 1.0);
#else
	uniform float h_bias;
	float bias = h_bias;
	vec2 dir = vec2(1.0, 0.0);
#endif

uniform bool matte_is_strength;
uniform bool bidirectional;

vec4 gblur()
{
	vec2 xy = gl_FragCoord.xy;
	vec2 st = xy / res;

	vec2 d = direction;

	// Is a directional blur
	if (blur_type == 1) {
		bias = 1.0;

		// Use an angle as the direction instead of a position vector
		if (use_angle) {
			float a = radians(angle);
			mat2 rm = mat2(
				cos(a), sin(a),
				sin(a), cos(a)
			);

			vec2 p = vec2(1.0, .5) - CENTER;

			p.x *= ratio;
			d = p * rm;
			d.x /= ratio;
			d += CENTER;
		}

		dir = d - CENTER;
	}

	float br = blur_amount * bias;
	float bg = blur_amount * bias;
	float bb = blur_amount * bias;
	float bm = blur_amount * bias;

	//Blur code by Lewis Saunders

	float support = max(max(max(br, bg), bb), bm) * 3.0;

	vec4 sigmas = vec4(br, bg, bb, bm);
	sigmas = max(sigmas, vec4(0.0001));

	vec4 gx, gy, gz;
	gx = 1.0 / (sqrt(2.0 * PI) * sigmas);
	gy = exp(-0.5 / (sigmas * sigmas));
	gz = gy * gy;

	vec4 a = gx * texture2D(INPUT, xy * texel);
	vec4 energy = gx;
	gx *= gy;
	gy *= gz;

	for(float i = 1; i <= support; i++) {
    a += gx * texture2D(INPUT, (xy - i * dir) * texel);

		if (blur_type == 0 || bidirectional) {
			// Is a xy guassian blur or a bidirectional blur

    	a += gx * texture2D(INPUT, (xy + i * dir) * texel);
			energy += 2.0 * gx;
		} else if (blur_type == 1) {
			// Is a directional blur

			energy += gx;
		}

		gx *= gy;
		gy *= gz;
	}

	a /= energy;

	return a;
}

void main(void)
{
	vec2 st = gl_FragCoord.xy / res;
	vec4 strength = vec4(1.0);

	if (strength_are_vectors && blur_vectors) {
		strength = gblur();
	} else {
		strength = texture2D(INPUT, st);
	}

	gl_FragColor = strength;
}
