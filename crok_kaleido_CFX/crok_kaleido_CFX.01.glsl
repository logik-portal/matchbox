//based on https://www.shadertoy.com/view/XtcXWM by zackpudil
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
#version 120

uniform sampler2D strength;
uniform float adsk_result_w, adsk_result_h, adsk_time, adsk_result_frameratio;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);
uniform float speed;
uniform float offset;
uniform float seed;
uniform int detail;
uniform bool antialiasing;
uniform int aa_strength;
uniform float aa_softness;

float time = adsk_time * 0.05 * speed + offset;

#define HALF_PIX 0.5
#define SPIRAL_NOISE_ITER 8


vec2 adsk_getCameraNearFar();
vec2 camNearFar=adsk_getCameraNearFar();
// camera view
mat4 adsk_getCameraViewInverseMatrix();
// camera projection information
vec2 input_texture_size = vec2(adsk_result_w, adsk_result_h);

mat4 adsk_getCameraProjectionMatrix();
mat4 camProj = adsk_getCameraProjectionMatrix();
vec4 camProjectionInfo = vec4(-2.0 / (input_texture_size.x*camProj[0][0]),
                              -2.0 / (input_texture_size.y*camProj[1][1]),
                              ( 1.0 - camProj[0][2]) / camProj[0][0],
                              ( 1.0 + camProj[1][2]) / camProj[1][1]);

//-----------------------------------------------------------------------------
// Compute the depth from a world space z
float z2d(float z)
{
   return (-z-camNearFar.x)/(camNearFar.y-camNearFar.x);
}

//-----------------------------------------------------------------------------
// Reconstruct camera-space P.xyz from screen-space S = (x, y) in pixels and
// depth.
vec3 screenToCamPos(vec2 ss_pos,float depth)
{
   float z = depth*(camNearFar.y-camNearFar.x)+camNearFar.x;
   vec3 cs_pos = vec3(((ss_pos + vec2(HALF_PIX))*
      camProjectionInfo.xy + camProjectionInfo.zw) * z, z);
   return -cs_pos;
}

//-----------------------------------------------------------------------------
// Recover the world position from the given camera position
vec3 camToWorldPos(vec3 c_pos)
{
   vec4 wpos = adsk_getCameraViewInverseMatrix()*vec4(c_pos,1.0);
   return wpos.w>0.0?wpos.xyz/wpos.w:wpos.xyz;
}


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
	for(int i = 0; i < detail; i++) {
		p = abs(p);
		p.xz *= rotate(-0.1 + 0.1*sin(time));
		p.xy *= rotate(0.3);
		p.yz *= rotate(0.0 + 0.2*cos(0.45*time));
		p = 2.0*p - 1.0 * seed;
	}

    float c = length(op.xz - vec2(0, 0.1*time)) - 0.08;

    return max(-c, (length(max(abs(p) - 1.7 + texture2D(strength, vec2(0.0)).r, 0.0)))*exp2(-float(it)));
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

    col = mix(col, vec3(10.0), 1.0 - exp(-0.16*t));
	return col;
}

float rand2(vec2 p) {
	return fract(sin(dot(p ,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void)
{
  // camera position in world (NB : z < 0)
  vec3 ro=camToWorldPos(vec3(0.0));
  // screen space pos of the current fragment
  ro *= .0022;
  vec3 col = vec3(0.0);

  if ( antialiasing )
  {
    float n = 0.0;
    for(int i=0; i < aa_strength; i++)
    {
      float aa_offset = rand2(vec2(i, i))-0.5;
      // get the fragment world position (NB : z < 0)
      vec3 pos = camToWorldPos(screenToCamPos(gl_FragCoord.xy + aa_offset * aa_softness, 1.0));
      // get the ray dir to march along
      vec3 rd=normalize(pos-ro);
      col += render(ro, rd);
    }
    col /= float(aa_strength);

  }
  else
  {
    // get the fragment world position (NB : z < 0)
    vec3 pos = camToWorldPos(screenToCamPos(gl_FragCoord.xy, 1.0));
    // get the ray dir to march along
    vec3 rd=normalize(pos-ro);
    // get the ray length to march along
    float rz=distance(pos,ro);
    col = render(ro, rd );
  }

  col = 1.0 - exp(-0.37*col);
  gl_FragColor = vec4(col.b) * 2.0 - 1.1;
}
