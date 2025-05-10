#version 120
// based on https://www.shadertoy.com/view/WdX3Wj by and

uniform sampler2D adsk_results_pass3;
uniform float adsk_result_w, adsk_result_h;
vec2 iResolution = vec2(adsk_result_w, adsk_result_h);
uniform int m_amount; // 6 // 13x13
uniform int num_iter;

#define BIN_COUNT 12
#define U00_11(X) X(0)X(1)X(2)X(3)X(4)X(5)X(6)X(7)X(8)X(9)X(10)X(11)
#define UNROLL(X) U00_11(X)

vec3 readInput(vec2 uv, int dx, int dy)
{
  vec2 img_res = iResolution.xy;
	return texture2D(adsk_results_pass3, uv + vec2(dx, dy) / img_res).rgb;
}

void main()
{
  vec2 img_res = iResolution.xy;
  vec2 res = iResolution.xy / img_res;
  vec2 img_size = img_res * max(res.x, res.y);
  vec2 img_org = 0.5 * (iResolution.xy - img_size);
  vec2 uv = (gl_FragCoord.xy - img_org) / img_size;
  vec3 ocol = readInput(uv, 0, 0);
  vec3 col = ocol;

	vec4 bins[BIN_COUNT];
	#define INIT(n) bins[n] = vec4(0);
  UNROLL(INIT)

	float vmin = 1.0;
	float vmax = 0.0;

	for (int y = -m_amount; y <= m_amount; y++)
	for (int x = -m_amount; x <= m_amount; x++)
	{
    vec3 img = readInput(uv, x, y);
		float v = (img.r + img.g + img.b) / 3.0;
		vmin = min(vmin, v);
		vmax = max(vmax, v);
	}

	for (int y = -m_amount; y <= m_amount; y++)
	for (int x = -m_amount; x <= m_amount; x++)
	{
    vec3 img = readInput(uv, x, y);
		float v = (img.r + img.g + img.b) / 3.0;
		int i = int(0.5 + ((v - vmin) / (vmax - vmin)) * float(BIN_COUNT));
		#define UPDATE(n) if (i == n) bins[n] += vec4(img.rgb, 1.0);
    UNROLL(UPDATE)
	}

	float mid = floor((float(m_amount * 2 + 1) * float(m_amount * 2 + 1)) / 2.0);
	float pos = 0.0;
  #define M1(i) col.rgb = pos <= mid && bins[i].a > 0.0 ?
	#define M2(i) bins[i].rgb / bins[i].aaa : col.rgb;
  #define M3(i) pos += bins[i].a;
  #define MEDIAN(i) M1(i)M2(i)M3(i)
  UNROLL(MEDIAN)
  gl_FragColor = vec4(col, 1.0);
}
