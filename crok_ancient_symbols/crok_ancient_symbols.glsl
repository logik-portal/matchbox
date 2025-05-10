#version 120
// based on https://www.shadertoy.com/view/wl2yDc by BackwardsCap

// --------[ Autodesk Uniforms start here ]---------- //
uniform float adsk_result_w, adsk_result_h, adsk_time;
uniform sampler2D iChannel0, iChannel1;
vec2 res = vec2(adsk_result_w, adsk_result_h);
// --------[ Autodesk Uniforms end here ]---------- //


// --------[ Shadertoy Globals start here ]---------- //
#define iTime adsk_time *.05
#define iResolution res
#define texture texture2D
#define fragCoord gl_FragCoord
#define fragColor gl_FragColor
#define iMouse vec3(0.0)
// --------[ Shadertoy Globals end here ]---------- //

//Ancient Symbols
//by Sam Gates (BackwardsCap)

//Code is gross; I will optimize it at a later date
#define R iResolution.xy
#define PI 3.1415927
#define m vec2(5.+2.*4.,10.)
#define SS(U) smoothstep(PX, 0., U)

float PHI = 1.61803398874989484820459;  // Golden Ratio

uniform bool MORPH;
uniform float size;
uniform float seed;
uniform float speed;

//Any advice on fixing the inconsistency on the connecting edges when you resize the screen would be very welcome
#define PX 20./R.y


float hash2 (vec2 p)
{
    float d = seed;
    if (MORPH)
    {
      d = iTime * speed + seed;
      vec2 pp = mod(p,m);
      d=floor(d*pp.x*pp.y)/30.;
    }
    return fract(sin(dot(p.xy,vec2(12389.1283,8941.1283)))*(12893.128933)+cos(floor(d)));
    //return fract(tan(distance(p*PHI, p)*1.0)*p.x);
}

mat2 rot(float a){return mat2(cos(a),-sin(a),sin(a),cos(a));}

//https://www.shadertoy.com/view/4llXD7
float B(vec2 p, vec2 b, vec4 r)
{
    r.xy = p.x>0.0?r.xy : r.zw;
    r.x = p.y>0.0 ? r.x : r.y;
    vec2 q = abs(p)-b+r.x;
    return SS(min(max(q.x,q.y),0.0)+length(max(q,0.0))-r.x);
}

bool removed(float h, vec2 p)
{
    vec2 lp = mod(p,m);
    float h2 = hash2(vec2(20.+h*(floor(p.y))+10.84));
    if(lp.x>=4.&&lp.x<11.||lp.y>=6.)return true;
    return h*dot(h,h2)*5.<=.5;
}


float C(vec2 p){return SS(length(p-.5)-.4);}

float CL(vec2 p, float a)
{
    vec2 bp = (p-.5);
    bp*=rot(PI/4.*a);
    bp.x+=.5;
    return B(bp, vec2(.6,.345), vec4(.3));
}

float CE(vec2 p, vec2 o)
{
    return B((p+o)*rot(PI/4.), vec2(.5), vec4(0));
}

float EL(vec2 p, float t)
{
    vec2 b = vec2(.5,.4-PX);
    p-=vec2(.5,.5);
    p*=rot(PI/2.*t);
    p.x+=PX;
    vec4 r = vec4(b.x-b.x/2.,b.x-b.x/2.,0,0);
    return B(p, b, r);
}

float D(vec2 p, float r)
{
    p-=.5;
    p*=rot(PI/2.*r);
    p+=.13;
    float b1 = B(p,vec2(.5),vec4(.5,0,0,0));
    p+=.77;
    float b2 = B(p,vec2(.5),vec4(0,0,0,.025));
    return b1-b2;
}


float T(vec2 p, float r)
{
    p-=.5;
    p*=rot(PI/2.*r);
    return B(p,vec2(.4-PX,.6), vec4(0));
}

float render(vec2 p, float h)
{
    bool neighbors[9];
    int ul=6,u=7,ur=8,l=3,me=4,r=5,dl=0,d=1,dr=2;
    int n=0;

    float o = 0.;

    for(float y=-1.;y<=1.;y++)
    {
        for(float x=-1.;x<=1.;x++){

            int i = int((x+1.)+(y+1.)*3.);

            vec2 pos = floor(p+vec2(x,y));

            neighbors[i]= !removed(hash2(pos),pos);

            if(i!=me&&neighbors[i])
            {
                n++;
            }
        }
    }

    p=fract(p);

    if(neighbors[me])
    {
        if(n==0) return C(fract(p));

        if(neighbors[u]&&neighbors[d]){

            float o = T(p,0.);
            if(neighbors[l])o+=EL(p+vec2(.175,0),0.);
            if(neighbors[r])o+=EL(p-vec2(.175,0),2.);
            return o;
        }
        if(neighbors[l]&&neighbors[r])
        {
            float o = T(p,1.);
            if(neighbors[u])o+=EL(p-vec2(0,.25),1.);
            if(neighbors[d])o+=EL(p+vec2(0,.25),3.);
            return o;
        }


        if(neighbors[u]&&!neighbors[d]&&!neighbors[l]&&!neighbors[r])
        {
            float o = EL(p-vec2(0,.3),1.);

            if(neighbors[dl]) o+=CL(p-vec2(.175),7.);
            if(neighbors[dr]) o+=CL(p-vec2(-.175,.175),5.);

            return o;
        }

        if(neighbors[d]&&!neighbors[u]&&!neighbors[l]&&!neighbors[r])
        {
            float o = EL(p+vec2(0,.3),3.);

            if(neighbors[ul]) o+=CL(p+vec2(-.175,.175),1.);
            if(neighbors[ur]) o+=CL(p+vec2(.175),3.);

            return o;
        }

        if(neighbors[l]&&!neighbors[r]&&!neighbors[d]&&!neighbors[u])
        {
            float o = EL(p+vec2(.3,0),0.);

            if(neighbors[ur]) o+=CL(p+vec2(.175,.175),3.);
            if(neighbors[dr]) o+=CL(p-vec2(-.175,.175),5.);

            return o;
        }

        if(neighbors[r]&&!neighbors[l]&&!neighbors[d]&&!neighbors[u])
        {
            float o = EL(p-vec2(.3,0),2.);

            if(neighbors[ul]) o+=CL(p+vec2(-.175,.175),1.);
            if(neighbors[dl]) o+=CL(p-vec2(.175),7.);

            return o;
        }
        float j = 0.0;
        if(!neighbors[u]&&neighbors[r]&&!neighbors[l]&&neighbors[d])j+= D(p,3.);
        if(neighbors[u]&&neighbors[r]&&!neighbors[l]&&!neighbors[d])j+= D(p,2.);
        if(!neighbors[u]&&!neighbors[r]&&neighbors[l]&&neighbors[d])j+= D(p,0.);
        if(neighbors[u]&&!neighbors[r]&&neighbors[l]&&!neighbors[d])j+= D(p,1.);
        if(neighbors[ul]&&!neighbors[l]&&!neighbors[u]) j+=CL(p+vec2(-.175,.175),1.);
        if(neighbors[dl]&&!neighbors[l]&&!neighbors[d]) j+=CL(p-vec2(.175),7.);
        if(neighbors[ur]&&!neighbors[r]&&!neighbors[u]) j+=CL(p+vec2(.175,.175),3.);
        if(neighbors[dr]&&!neighbors[r]&&!neighbors[d]) j+=CL(p-vec2(-.175,.175),5.);


        return  j;
    }else{
        float o = 0.0;
        if(!neighbors[ul]&&neighbors[u]&&neighbors[l])o+= CE(p,vec2(.07,-1.15));
        if(!neighbors[ur]&&neighbors[u]&&neighbors[r])o+= CE(p, vec2(-1.11));
        if(!neighbors[dl]&&neighbors[d]&&neighbors[l])o+= CE(p,vec2(.11));
        if(!neighbors[dr]&&neighbors[d]&&neighbors[r])o+= CE(p,vec2(-1.11,.11));
        return o;
    }
}

void main(void)
{
    vec2 f = gl_FragCoord.xy;
    vec2 p = ((2.0*f-R)/R.y), u=p;
    p*= (30.0 * size);
    p-=vec2(51,-3.);
    vec2 lp = (p);
    p=floor(p);
    float hash = hash2(p);
    gl_FragColor.rgb = vec3(clamp(render(lp,hash),0.,1.));
}
