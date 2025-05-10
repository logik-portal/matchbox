
uniform float adsk_time;
uniform float adsk_result_w, adsk_result_h;
uniform float paramFlameSpeed;
uniform vec2 paramFlameDirection;
uniform vec3 paramColor1;
uniform vec3 paramColor2;


float noise(vec3 p) //Thx to Las^Mercury
{
	vec3 i = floor(p);
	vec4 a = dot(i, vec3(1., 57., 21.)) + vec4(0., 57., 21., 78.);
	vec3 f = cos((p-i)*acos(-1.))*(-.5)+.5;
	a = mix(sin(cos(a)*a),sin(cos(1.+a)*(1.+a)), f.x);
	a.xy = mix(a.xz, a.yw, f.y);
	return mix(a.x, a.y, f.z);
}

//-----------------------------------------------------------------------------
// Scene/Objects
//-----------------------------------------------------------------------------
float sphere(vec3 p, vec4 spr)
{
	return length(spr.xyz-p) - spr.w;
}

float fire(vec3 p)
{
	float d= sphere(p*vec3(1.,.5,1.), vec4(.0,-1.,.0,1.));
	return d+(noise(p+vec3(.0,adsk_time* paramFlameSpeed /100.0,.0))+noise(p*3.)*.5)*.25*(p.y) ;
}
//-----------------------------------------------------------------------------
// Raymarching tools
//-----------------------------------------------------------------------------
float scene(vec3 p)
{
	return min(100.-length(p) , abs(fire(p)) );
}



vec4 Raymarche(vec3 org, vec3 dir)
{
	float d=0.0;
	vec3  p=org;
	float glow = 0.0;
	float eps = 0.02;
	bool glowed=false;
	for(int i=0; i<64; i++)
	{
		d = scene(p) + eps;
		p += d * dir;
		if( d>eps )
		{
			if( fire(p) < .0)
				glowed=true;
			if(glowed)
       			glow = float(i)/64.;
		}
	}
	return vec4(p,glow);
}

//-----------------------------------------------------------------------------
// Main functions
//-----------------------------------------------------------------------------

void main()
{
    vec2 iResolution = vec2(adsk_result_w,adsk_result_h);
	vec2 v = -1.0 + 2.0 * gl_FragCoord.xy / iResolution.xy;
	v.x *= iResolution.x/iResolution.y;
	vec3 org = vec3(0.,-2.,4.);
	vec3 dir   = normalize(vec3(v.x*paramFlameDirection.x,-v.y,paramFlameDirection.y));
	vec4 p = Raymarche(org,dir);
	float glow = p.w;
	gl_FragColor = mix(vec4(0.), mix(vec4(paramColor1.x,paramColor1.y,paramColor1.z,1.),vec4(paramColor2.x,paramColor2.y,paramColor2.z,1.),p.y*.02+.4), pow(glow*2.,4.));

}