

float   adsk_getLuminance( vec3 rgb );
vec3 adsk_rgb2hsv( in vec3 src );
vec3 adsk_hsv2rgb( in vec3 src );

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D Front;
uniform sampler2D Matte;
uniform int op;

uniform float red_mix;
uniform float green_mix;
uniform float blue_mix;
uniform float cyan_mix;
uniform float magenta_mix;
uniform float yellow_mix;
uniform float orange_mix;
uniform float purple_mix;
uniform float gain;
uniform int yuv_out;
uniform float gamma;
uniform int matte_out;

uniform bool clamp_output;
uniform bool negate;
uniform bool show_original;
uniform float sat;

uniform float rt, gt, bt, ct, mt, yt, pt, ot;

vec2 rotate(vec2 uv, float aa)
{
	float a = radians(aa);

	mat2 rotationMatrice = mat2( cos(-a), -sin(-a),
                          sin(-a), cos(-a) );

	return uv * rotationMatrice;
}

vec3 to_yuv(vec3 col)
{
	mat3 yuv = mat3
	(
		.2126, .7152, .0722,
		-.09991, -.33609, .436,
		.615, -.55861, -.05639
	);

	return col * yuv;
}

vec3 to_rgb(vec3 col)
{
	mat3 rgb = mat3
	(
		1.0, 0.0, 1.28033,
		1.0, -.21482, -.38059,
		1.0, 2.12798, 0.0
	);
	return col * rgb;
}

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec3 front = texture2D(Front, st).rgb;
	float bw_front = adsk_getLuminance(front);

	front = mix(vec3(bw_front), front, sat);

	vec3 yuv_front = to_yuv(front);
	float yuv_front_sum = yuv_front.g + yuv_front.b;
	vec3 hsv_front = adsk_rgb2hsv(front);

	float i_matte = texture2D(Matte, st).r;

	vec3 invfront = yuv_front;
	invfront.gb = rotate(invfront.gb, 180);
	invfront = to_rgb(invfront);

	vec3 red = vec3(1.0, 0.0, 0.0);
	vec3 green = vec3(0.0, 1.0, 0.0);
	vec3 blue = vec3(0.0, 0.0, 1.0);
	vec3 cyan = vec3(1.0 - red);
	vec3 magenta = vec3(1.0 - green);
	vec3 yellow = vec3(1.0 - blue);
	vec3 orange = vec3(1.0, .5, 0);
	//orange = vec3(.631, .471, .378);
	vec3 purple = vec3(.5, .0, .5);

	float comp = bw_front;
	float m = 0.0;
	float c = 0.0;
	float t = .5;
	float o_m = i_matte;

	vec3 yuv = to_yuv(red);
	float ysum = yuv.g + yuv.b;
	float matte = 1.0 - abs(yuv_front_sum - ysum);
	matte = pow(matte, rt);

	matte = clamp(matte, 0.0, 1.0);
	comp = mix(comp, comp * red_mix, matte);

	if (matte_out == 1) {
		o_m = matte;
	}

	yuv = to_yuv(orange);
	ysum = yuv.g + yuv.b;
	matte = 1.0 - abs(yuv_front_sum - ysum);
	matte = pow(matte, ot);
	matte = clamp(matte, 0.0, 1.0);
	comp = mix(comp, comp * orange_mix, matte);

	if (matte_out == 2) {
		o_m = matte;
	}

	yuv = to_yuv(yellow);
	ysum = yuv.g + yuv.b;
	matte = 1.0 - abs(yuv_front_sum - ysum);
	matte = pow(matte, yt);
	matte = clamp(matte, 0.0, 1.0);
	comp = mix(comp, comp * yellow_mix, matte);

	if (matte_out == 3) {
		o_m = matte;
	}

	yuv = to_yuv(green);
	ysum = yuv.g + yuv.b;
	matte = 1.0 - abs(yuv_front_sum - ysum);
	matte = pow(matte, gt);
	matte = clamp(matte, 0.0, 1.0);
	comp = mix(comp, comp * green_mix, matte);

	if (matte_out == 4) {
		o_m = matte;
	}

	yuv = to_yuv(cyan);
	ysum = yuv.g + yuv.b;
	matte = 1.0 - abs(yuv_front_sum - ysum);
	matte = pow(matte, ct);
	matte = clamp(matte, 0.0, 1.0);
	comp = mix(comp, comp * cyan_mix, matte);

	if (matte_out == 5) {
		o_m = matte;
	}

	yuv = to_yuv(blue);
	ysum = yuv.g + yuv.b;
	matte = 1.0 - abs(yuv_front_sum - ysum);
	matte = pow(matte, bt);
	matte = clamp(matte, 0.0, 1.0);
	comp = mix(comp, comp * blue_mix, matte);

	if (matte_out == 6) {
		o_m = matte;
	}

	yuv = to_yuv(purple);
	ysum = yuv.g + yuv.b;
	matte = 1.0 - abs(yuv_front_sum - ysum);
	matte = pow(matte, pt);
	matte = clamp(matte, 0.0, 1.0);
	comp = mix(comp, comp * purple_mix, matte);

	if (matte_out == 7) {
		o_m = matte;
	}

	yuv = to_yuv(magenta);
	ysum = yuv.g + yuv.b;
	matte = 1.0 - abs(yuv_front_sum - ysum);
	matte = pow(matte, mt);
	matte = clamp(matte, 0.0, 1.0);
	comp = mix(comp, comp * magenta_mix, matte);

	if (matte_out == 8) {
		o_m = matte;
	}

	vec3 out_col = vec3(comp);

	out_col = mix(front, out_col, i_matte);

	//out_col = lr;
	//out_col = smoothstep(.5, 1.0, lr);
	//out_col = lr / 100 * red_mix;

	gl_FragColor= vec4(out_col, o_m);
	//gl_FragColor.rgb = front;
}
