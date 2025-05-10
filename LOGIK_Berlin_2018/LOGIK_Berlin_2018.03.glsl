#version 120

uniform sampler2D adsk_results_pass2;
uniform float adsk_time, adsk_result_w, adsk_result_h;


float scale = 9.67;
float b_threshold = 47.40;
float l_threshold = 25.37;
float bw_bias = 7.19;
float rgb_offset = 4.9;
float bias = 10.0;
float opacity = 1.0;


vec2 resolution = vec2(adsk_result_w, adsk_result_h);
float time = adsk_time *.05;
const int lookupSize = 64;


vec3 saturation(vec3 rgb, float adjustment)
{
    // Algorithm from Chapter 16 of OpenGL Shading Language
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}

// Real contrast adjustments by  Miles
vec3 adjust_contrast(vec3 col, vec4 con)
{
vec3 c = con.rgb * vec3(con.a);
vec3 t = (vec3(1.0) - c) / vec3(2.0);
t = vec3(.18);
col = (1.0 - c.rgb) * t + c.rgb * col;
return col;
}

float getGrayscale(vec2 coords)
{
	vec2 uv = coords / resolution.xy;
	vec3 sourcePixel = texture2D(adsk_results_pass2, uv).rgb;
	return length(sourcePixel*vec3(0.2126,0.7152,0.0722));
}


vec3 difference( vec3 s, vec3 d )
{
	return abs(d - s);
}

float rand2(vec2 co)
{
	return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

vec3 rand1(vec2 uv) {
	time = 1.0;
	vec2 c = ((.01)*resolution.x)*vec2(1.,(resolution.y/resolution.x));
	vec3 col = vec3(0.0);

   	float r = rand2(vec2((2.+time) * floor(uv.x*c.x)/c.x, (2.+time) * floor(uv.y*c.y)/c.y ));
   	float g = rand2(vec2((5.+time) * floor(uv.x*c.x)/c.x, (5.+time) * floor(uv.y*c.y)/c.y ));
   	float b = rand2(vec2((9.+time) * floor(uv.x*c.x)/c.x, (9.+time) * floor(uv.y*c.y)/c.y ));

	col = vec3(r,g,b);

	return col;
}


// Using Ashima's simplex noise
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}


float n_scale = clamp(rand2(vec2((time), (time) * floor(2.0)))* 5.0, 0.0, scale);
float n_g_noise = rand2(vec2((time), (5.+time) * floor(300.0))) * 3123.0;


void main(void)
{
	vec2 uv = gl_FragCoord.xy / resolution.xy;
	vec3 original = texture2D(adsk_results_pass2, uv).rgb;
	vec2 block = floor(gl_FragCoord.xy / vec2(n_scale));
	vec2 uv_noise = block / vec2(n_g_noise);
	uv_noise += floor(vec2(time) * vec2(1234.0, 3543.0)) / vec2(64);
	vec3 d_noise = rand1(uv_noise);
	float block_thresh = pow(fract(time * 1236.0453), b_threshold);
	float line_thresh = pow(fract(time * 2236.0453), l_threshold);

	vec3 col = vec3(0.0);
	vec3 f_col = original;

	vec2 uv_r = uv, uv_g = uv, uv_b = uv;

	if (d_noise.r < block_thresh ||
		rand1(vec2(uv_noise.y, 0.0)).g < line_thresh)
	{
		vec2 dist = (fract(uv_noise) - 0.5) * 0.3;
		uv_r += dist * 0.01 * rgb_offset;
		uv_g += dist * 0.02 * rgb_offset;
		uv_b += dist * 0.0125 * rgb_offset;
	}
	gl_FragColor.r = texture2D(adsk_results_pass2, uv_r).r;
	gl_FragColor.g = texture2D(adsk_results_pass2, uv_g).g;
	gl_FragColor.b = texture2D(adsk_results_pass2, uv_b).b;
	col = gl_FragColor.rgb;

	//col = mix(gl_FragColor.rgb, f_col, 1.0);

	if (d_noise.g < block_thresh)
		col.rgb = col.ggg;

	if (rand1(vec2(uv_noise.y, 0.0)).b * 3.5 < line_thresh)
		col.rgb = vec3(0.0, dot(col.rgb, vec3(1.0)), 0.0);

	if (d_noise.g * 1.5 < block_thresh ||
		rand1(vec2(uv_noise.y, 0.0)).g * 2.5 < line_thresh )
	{
		float line = fract(gl_FragCoord.y / 3.0);
		vec3 mask = vec3(3.0, 0.0, 0.0);
		if (line > 0.333)
			mask = vec3(0.0, 3.0, 0.0);
		if (line > 0.666)
			mask = vec3(0.0, 0.0, 3.0);
		col = col.rgb * mask;
	}

  float blend = snoise(vec2(adsk_time*200.));
  blend = clamp((blend-(1.0-bias))*999999.0, 0.0, opacity);
	col = mix(f_col, col, blend);
	col = saturation(col, 0.0);
	col = vec3(col.r* 0.98, col.g*1.12, col.b * 1.3);
	col = adjust_contrast(col, vec4(1.3));
	gl_FragColor = vec4(col, 1.0);
}
