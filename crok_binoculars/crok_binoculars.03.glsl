#version 120
// creating the binocluar mask
uniform float adsk_result_w, adsk_result_h, adsk_time, adsk_result_frameratio;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);
uniform float aspect, size, offset;

float circle(vec2 uv, vec2 p, float r, float blur){
  float d = length(uv - p);
  float c = smoothstep(r, r - blur, d);
  return c;
}

vec3 screen( vec3 s, vec3 d )
{
	return s + d - s * d;
}

vec3 multiply( vec3 s, vec3 d )
{
	return s*d;
}

float bias(float x, float b)
{
    b = -log2(1.0 - b);
    return 1.0 - pow(abs(1.0 - pow(abs(x), 1./b)), b);
}

void main()
{
	vec2 uv = gl_FragCoord.xy / resolution.xy;
  uv.x *= adsk_result_frameratio * aspect;
  vec2 p = vec2(0.5 * adsk_result_frameratio * aspect, 0.5);
  float c = circle(uv, vec2(p.x - offset * size, p.y), size, 0.99999999 * size);
  c += circle(uv, vec2(p.x + offset * size, p.y), size, 0.99999999 * size);
  c = clamp(c, 0.0, 1.0);
  float mask = bias(c, 1.0 - 0.01);

  gl_FragColor = vec4(vec3(mask), c);
}
