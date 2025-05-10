//based on www.shadertoy.com/view/MdjGWc by Antonalog
#version 120

uniform float adsk_result_w, adsk_result_h, adsk_time;

float detail = 1.05;
float fov_a = 1.0;

int STEPS =  128;
float slices = 512.;

vec3 auge = vec3(1.0, 0.77, 1.0);
vec3 lookAt = vec3(20.0);
int turbulence_steps = 6;

vec2 iResolution = vec2(adsk_result_w, adsk_result_h);
float iGlobalTime = adsk_time * 0.025 + 5.;

// hash based 3d value noise
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float Noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*((1.0+1.0)-1.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;
    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
           mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
           mix(mix( hash(n+113.0), hash(n+114.0),f.x),
           mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}

// 3D noise function (IQ)
float Noise2(vec3 p)
{
	vec3 ip=floor(p);
  p-=ip;
  vec3 s=vec3(7,157,113);
  vec4 h=vec4(0.,s.yz,s.y+s.z)+dot(ip,s);
  p=p*p*(3.-2.*p);
  h=mix(fract(sin(h)*43758.5),fract(sin(h+s.x)*43758.5),p.x);
  h.xy=mix(h.xz,h.yw,p.y);
  return mix(h.x,h.y,p.z);
}

void MakeViewRay(in vec2 fragCoord, out vec3 eye, out vec3 ray)
{
	vec2 ooR = 1./iResolution.xy;
    vec2 q = fragCoord.xy * ooR;
    vec2 p =  2.*q - 0.75;
    p.x *= iResolution.x * ooR.y;

    //vec3 lookAt = vec3(20.0);
		eye = vec3(0.3 * auge.x, 1.3 * auge.y, -1.5 * auge.z) + lookAt;

    // camera frame
    vec3 fo = normalize(lookAt-eye);
    vec3 ri = normalize(vec3(fo.z, 0., -fo.x ));
    vec3 up = normalize(cross(fo,ri));

    float fov = .27 * fov_a;

    ray = normalize(fo + fov*p.x*ri + fov*p.y*up);
}

vec4 BlendUnder(vec4 accum,vec4 col)
{
	col = clamp(col,vec4(0),vec4(1));
	col.rgb *= col.a;
	accum += col*(1.0 - accum.a);
	return accum;
}

vec2 Turbulence2(vec3 p)
{
	vec2 t = vec2(0.0);
	float oof = 1.0;
	for (int i=0; i<turbulence_steps; i++)
	{
		t += abs(Noise2(p))*oof;
		oof *= 0.5;
		p *= 2.2 * detail;	//bigger number, more detail
	}

	return t-vec2(1.);
}

vec2 PhaseShift2(vec3 p)
{
	float g = (p.y+2.);	 //fall off with height
	p *= .4;
	p.x += iGlobalTime * .02;
	p.y += -iGlobalTime;
	return g * Turbulence2(p);
}

float Density(vec3 p)
{
 	//rotate Z randomly about Y  =~ swirly space
	float t = Noise(p);
	t *= (180. / 3.1415927)*.005 * (p.y+2.);
	float s = sin(t); float c = cos(t);
	p.z = p.x*s+p.z*c;

	//
	p.xz += PhaseShift2(p);

	//repeat it just because we can
	float f = 2.;
	p.xz = mod(p.xz, f) - f*.5;

	//column as distance from y axis
	float rx = dot(p.xz,p.xz)*5.  -p.y*0.25;
	if (rx < 1.0)
	{
		float s = sin(3.1415927*rx);	//hollow tube
		return s*s*s*s;
	}

	return 0.;
}

vec4 March(vec4 accum, vec3 viewP, vec3 viewD, vec2 mM)
{

	float Far = 16.0;

	float sliceStart = log2(mM.x)*(slices/log2(Far));
	float sliceEnd = log2(mM.y)*(slices/log2(Far));

	float last_t = mM.x;

	for (int i=0; i<STEPS; i++)
	{
		sliceStart += 1.0;
		float sliceI = sliceStart;// + float(i);	//advance an exponential step
		float t = exp2(sliceI*(log2(Far)/slices));	//back to linear

		vec3 p = viewP+t*viewD;

		float dens = Density(p);
		dens *= (t-last_t)*1.5;

		//color gradient
		vec3 c = mix( vec3(0.5,0.6,.7), vec3(0.2), p.y);
		//vec3 c = mix( vec3(0.5,0.6,.7), vec3(0.52),1.0);


		c *= min(-t*.6+7.,1.);

		accum = BlendUnder(accum,vec4(c,dens));

		last_t=t;
	}

	return accum;
}

void main(void)
{
	vec3 viewP = vec3(0.0);
	vec3 viewD = vec3(3.0);;
  MakeViewRay(gl_FragCoord.xy,viewP, viewD);
  vec3 c = vec3(0.0);
	vec4 a = March(vec4(0.0), vec3(2.0), viewD, vec2(2.0, 0.40));
	c = BlendUnder(a,vec4(c,1.)).xyz;
	c = pow(c,vec3(1./1.1));
  c = c.ggg;
	gl_FragColor = clamp(vec4(c.r-0.03, c.g- 0.005, c.b +0.015, 1.0) * 2.5, 0.0, 1.0);
}
