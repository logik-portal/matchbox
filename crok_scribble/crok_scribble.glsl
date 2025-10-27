#version 120
#extension GL_ARB_shader_texture_lod : enable
// based on www.shadertoy.com/view/tsV3Rw
// created by florian berger (flockaroo) - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// scribble blue in tweets of two
// improved + golfed down ballpoint effect
// check "https://10xfx.com" for this and more effects for AfterEffects and OpenFX

// --------[ Autodesk Uniforms start here ]---------- //
uniform float adsk_result_w, adsk_result_h, adsk_time;
uniform sampler2D front;
vec2 res = vec2(adsk_result_w, adsk_result_h);
// --------[ Autodesk Uniforms end here ]---------- //

uniform float contrast;
uniform float distortion;
uniform float line_length; // 20.0;
uniform int itterations; // 3000
uniform int p1;
uniform float p2;
//int itterations = 3000;
//float contrast = 30.0;
//float density = 1.0;
//float line_length = 20.0;


// --------[ Shadertoy Globals start here ]---------- //
#define iTime adsk_time *.05 * speed + offset
#define iResolution res
#define fragCoord gl_FragCoord.xy
#define fragColor gl_FragColor
// --------[ Shadertoy Globals end here ]---------- //

// --------[ Original ShaderToy starts here ]---------- //

#define R res
#define V(p) texture2DLod(front,(p)/R,.5).y

void main( void )
{
	vec2 f = fragCoord;
	vec4 c = vec4(0.0);
	float S = sqrt(R.x)/contrast,h,s;
    c-=c-1.;
    vec2 g,d=R/2E2,p,q,v,i,e=vec2(d.x*.2 * distortion,0);
    for(int j=0;j<itterations;j++)
    {
        int k=j/16;
    	//if(j%16==0) { i=floor(f/d)+vec2(k%13,k/13)-6.; s=mod(i.y,2.)-.5; p=(i+s)*d; v-=v; }
			if(mod(j,16)==0) { i=floor(f/d)+vec2(mod(k,13),k/13)-6; s=mod(i.y,2.)-.5; p=(i+s)*d; v-=v; }
	    q=p;
        g=V(p)-vec2(V(p-e),V(p-e.yx));
        h=pow(dot(g,g),0.3) * line_length;
        v=mix(v,
              mat2( cos( .8*vec4(4,2,6,4) + atan(h)*1.3*s+s ) ) * normalize(g),
              atan(h*h/8.));
        p+=v*d.x;
	    g=q-p; q=f-p; float l=length(g); g/=l; h=dot(q,g);
		c-=vec4(1.0,1.0,1.0,1.0)*max(S-max(S-min(l-h,h),abs(dot(q,g.yx*vec2(1,-1)))),0.);
		}
		gl_FragColor = c;
}
