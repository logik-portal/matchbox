//Heavily Inspired from https://www.shadertoy.com/view/XssGz8

#version 120

float adsk_getLuminance( vec3 );

uniform float adsk_result_frameratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

#define TOWARP adsk_results_pass5
#define STRENGTH adsk_results_pass4
#define PI 3.141592653589793238462643383279502884197969
#define EPSILON 0.000011


uniform sampler2D TOWARP;
uniform sampler2D STRENGTH;

uniform int samples;
uniform vec2 center;
uniform float scale, scale_x, scale_y;
uniform bool repeat_texture;
uniform float pos_x, pos_y, pos_z;
uniform bool warp_matte;
uniform bool front_is_back;
uniform bool matte_is_strength;
uniform bool strength_are_vectors;
uniform bool show_vectors;
uniform bool motion_only;
uniform bool warped_only;

bool isInTex( const vec2 coords )
{
        return coords.x >= 0.0 && coords.x <= 1.0 &&
                    coords.y >= 0.0 && coords.y <= 1.0;
}

vec4 offset_color(float amount)
{
	//when times goes past half samples lo is black;
	float lo = step(amount ,0.5);
  float hi = 1.0 - lo;

	float a = 1.0 / 6.0;
	float b = 5.0 / 6.0;

	// times gets closer to samples, x gets brighter, when times == samples, x is clamped to white;
	float x = clamp( (amount - a) / (b - a), 0.0, 1.0 );

	//when x gets brighter, w becomes darker
	float w = clamp(1.0 - abs(2.0 * x - 1.0), 0.0, 1.0);

	// times starts red and as it gets closer to samples it goes orange, green, blue
	vec3 rgb = vec3(lo, 1.0, hi) * vec3(1.0 - w, w, 1.0 - w);

	// if times starts at 0 and goes to 3, the result is, dark, bright, darker dark
	float lum = adsk_getLuminance(rgb);

	// linearize

	vec4 color = vec4(rgb, lum);

	return color;
}

vec2 scale_coords(vec2 coords, vec2 center, vec2 scale_amount)
{
	coords -= center;
	coords /= scale_amount;
	coords += center;

	return coords;
}

void main()
{
	vec2 st = gl_FragCoord.xy / res;

	vec4 front = texture2D(TOWARP, st);
  vec4 strength_texture = texture2D(STRENGTH, st);
	vec4 comp = vec4(0.0);
	vec4 warped = vec4(0.0);
	vec4 total = vec4(0.0);

  vec2 new_center = center;

  if (motion_only) {
	   strength_texture = abs(vec4(adsk_getLuminance(strength_texture.rgb)));
  }

	float matte = front.a;

	if (matte_is_strength) {
		strength_texture = vec4(matte);
	}

	float sample_norm = 1.0 / float(samples);

	for (int i = 0; i < samples; i++)
	{
		float amount = float(i) * sample_norm;
		vec4 color = offset_color(amount);

		total += color;

    vec3 translate = vec3(pos_x, pos_y, pos_z) * vec3(texel, texel.x) * vec3(amount) * strength_texture.rgb + vec3(0.0, 0.0, 1.0);
    vec2 scale_uvs = vec2(scale_x, scale_y) * vec2(scale)* texel * vec2(amount) * abs(vec2(strength_texture.b)) + vec2(1.0);

		vec2 coords = st;

		if (i == 0) {
			coords = scale_coords(coords, new_center, vec2(1.0));
		} else {

      coords = scale_coords(coords, new_center, scale_uvs);
      coords = scale_coords(coords, new_center, vec2(translate.z));
		}

    coords -= translate.xy;

		if (isInTex(coords))
		{
			warped += color * texture2D(TOWARP, coords);
		}
	}

	warped /= total;

	if (warp_matte)
	{
		matte = warped.a;
	}

	comp = mix(front, warped, matte);

  if (warped_only) {
    comp = warped * warped.a;
  }

	comp.a = matte;

  if (show_vectors && strength_are_vectors) {
    comp = strength_texture;
  }

	gl_FragColor = comp;
}
