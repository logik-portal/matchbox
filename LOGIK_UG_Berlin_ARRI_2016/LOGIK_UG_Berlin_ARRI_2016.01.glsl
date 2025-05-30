//based on https://www.shadertoy.com/view/XtcXWM by zackpudil
#version 120

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h, adsk_time, adsk_result_frameratio;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);

float time = adsk_time * 0.25;

float hash(float n) {
    return fract(sin(n)*43578.5453);
}

mat2 rotate(float a) {
	float s = sin(a);
	float c = cos(a);

	return mat2(c, s, -s, c);
}

float de(vec3 p) {
	vec3 op = p;
	p = fract(p + 0.5) - 0.5;
	p.xz *= rotate(3.14159);
	const int it = 7;
	for(int i = 0; i < it; i++) {
		p = abs(p);
		p.xz *= rotate(-0.1 + 0.1*sin(time));
		p.xy *= rotate(0.3);
		p.yz *= rotate(0.0 + 0.2*cos(0.45*time));
		p = 2.0*p - 1.0;
	}

    float c = length(op.xz - vec2(0, 0.1*time)) - 0.08;

	return max(-c, (length(max(abs(p) - 1.7 + texture2D(front, vec2(0)).r, 0.0)))*exp2(-float(it)));
}

float trace(vec3 ro, vec3 rd, float mx) {
	float t = 0.0;
	for(int i = 0; i < 100; i++) {
		float d = de(ro + rd*t);
		if(d < 0.001*t || t >= mx) break;
		t += d;
	}
	return t;
}

vec3 normal(vec3 p) {
	vec2 h = vec2(0.001, 0.0);
	vec3 n = vec3(
		de(p + h.xyy) - de(p - h.xyy),
		de(p + h.yxy) - de(p - h.yxy),
		de(p + h.yyx) - de(p - h.yyx)
	);
	return normalize(n);
}

float ao(vec3 p, vec3 n) {
	float o = 0.0, s = 0.005;
	for(int i= 0; i < 15; i++) {
		float d = de(p + n*s);
		o += (s - d);
		s += s/(float(i) + 1.0);
	}
	return 1.0 - clamp(o, 0.0, 1.0);
}

vec3 render(vec3 ro, vec3 rd) {
	vec3 col = vec3(1);

	float t = trace(ro, rd, 10.0);
    if(t < 10.0) {
        vec3 pos = ro + rd*t;
        vec3 nor = normal(pos);
        vec3 ref = normalize(reflect(rd, nor));

        float occ = ao(pos, nor);
        float dom = smoothstep(0.0, 0.3, trace(pos + nor*0.001, ref, 0.3));

        col = 0.1*vec3(occ);
        col += clamp(1.0 + dot(rd, nor), 0.0, 1.0)*mix(vec3(1), vec3(1.0, 0.3, 0.3), 1.0 - dom);
		col *= vec3(0.7, 3.0, 5.0);
    }

    col = mix(col, vec3(10), 1.0 - exp(-0.16*t));
	return col;
}

void main(void)
{
	vec2 uv = (-resolution + 2.0*gl_FragCoord.xy)/resolution.y;
  uv.y *= adsk_result_frameratio;
	float atime = 0.1*time;
	vec3 ro = vec3(0.0, 0.0, atime);
  vec3 la = vec3(vec2(0.0), atime + 1.0);

	vec3 ww = normalize(la-ro);
	vec3 uu = normalize(cross(vec3(0, 1, 0), ww));
	vec3 vv = normalize(cross(ww, uu));
  mat3 ca = mat3(uu, vv, ww);
	vec3 rd = normalize(ca*vec3(uv, 1.97));

	vec3 col = render(ro, rd);

	col = 1.0 - exp(-0.37*col);
	gl_FragColor = vec4(col.b) * 2.0 - 1.1;
}
