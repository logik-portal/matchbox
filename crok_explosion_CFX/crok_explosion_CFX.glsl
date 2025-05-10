#version 120

// "Volumetric explosion" by Duke
// https://www.shadertoy.com/view/lsySzd
//-------------------------------------------------------------------------------------
// Based on "Supernova remnant" (https://www.shadertoy.com/view/MdKXzc)
// and other previous shaders
// otaviogood's "Alien Beacon" (https://www.shadertoy.com/view/ld2SzK)
// and Shane's "Cheap Cloud Flythrough" (https://www.shadertoy.com/view/Xsc3R4) shaders
// Some ideas came from other shaders from this wonderful site
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
//-------------------------------------------------------------------------------------

uniform sampler2D front, depth_matte;
uniform int steps, detail;

#define HALF_PIX 0.5
uniform sampler2D depth;

uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 iResolution = vec2(adsk_result_w, adsk_result_h);
uniform float Speed;
uniform float Offset;
float time = adsk_time *.05 * Speed + 10.0 + Offset;

uniform vec3 lightColor;  // main colour for the explosion
uniform vec3 sphere_center; // position of the center of the explosion
float sphere_radius = 500.0; // size of the sphere containing the explosion

// CameraFX part start
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
// Compute the depth from a world space z
float z2d(float z)
{
	return (-z-camNearFar.x)/(camNearFar.y-camNearFar.x);
}
// Reconstruct camera-space P.xyz from screen-space S = (x, y) in pixels and depth.
vec3 screenToCamPos(vec2 ss_pos,float depth)
{
	float z = depth*(camNearFar.y-camNearFar.x)+camNearFar.x;
	vec3 cs_pos = vec3(((ss_pos + vec2(HALF_PIX))*
	camProjectionInfo.xy + camProjectionInfo.zw) * z, z);
	return -cs_pos;
}
// Recover the world position from the given camera position
vec3 camToWorldPos(vec3 c_pos)
{
	vec4 wpos = adsk_getCameraViewInverseMatrix()*vec4(c_pos,1.0);
	return wpos.w>0.0?wpos.xyz/wpos.w:wpos.xyz;
}
// CameraFX part end


//-------------------
#define pi 3.14159265
#define R(p, a) p=cos(a)*p+sin(a)*vec2(p.y, -p.x)

float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
   return noise(p*.06125)*.5 + noise(p*.125)*.25 + noise(p*.25)*.125 + noise(p*.4)*.2;
}

float Sphere( vec3 p, float r )
{
    return length(p)-r;
}

//==============================================================
// otaviogood's noise from https://www.shadertoy.com/view/ld2SzK
//--------------------------------------------------------------
// This spiral noise works by successively adding and rotating sin waves while increasing frequency.
// It should work the same on all computers since it's not based on a hash function like some other noises.
// It can be much faster than other noise functions if you're ok with some repetition.
float nudge = 4.;	// size of perpendicular vector
float normalizer = 1.0 / sqrt(1.0 + nudge*nudge);	// pythagorean theorem on that perpendicular to maintain scale
float SpiralNoiseC(vec3 p)
{
    float n = -mod(time * 0.2,-2.); // noise amount
    float iter = 2.0;
    for (int i = 0; i < detail ; i++)
    {
        // add sin and cos scaled inverse with the frequency
        n += -abs(sin(p.y*iter) + cos(p.x*iter)) / iter;	// abs for a ridged look
        // rotate by adding perpendicular and scaling down
        p.xy += vec2(p.y, -p.x) * nudge;
        p.xy *= normalizer;
        // rotate on other axis
        p.xz += vec2(p.z, -p.x) * nudge;
        p.xz *= normalizer;
        // increase the frequency
        iter *= 1.733733;
    }
    return n;
}

float VolumetricExplosion(vec3 p)
{
    float final = Sphere(p,4.0);
    final += fbm(p*50.0);
    final += SpiralNoiseC(p.zxy*0.4132+333.)* 6.0; //1.25;

    return final;
}

float map(vec3 p)
{
	float VolExplosion = VolumetricExplosion(p/0.5)*0.5; // scale
	return VolExplosion;
}

//--------------------------------------------------------------

// assign color to the media
vec3 computeColor( float density, float radius )
{
	// color based on density alone, gives impression of occlusion within
	// the media
	vec3 result = mix( vec3(1.0,0.9,0.8), vec3(0.4,0.15,0.1), density );

	// color added to the media
	vec3 colCenter = 7.*vec3(0.8,1.0,1.0);
	vec3 colEdge = 1.5*vec3(0.48,0.53,0.5);
	result *= mix( colCenter, colEdge, min( (radius+.05)/.9, 1.15 ) );

	return result;
}

bool RaySphereIntersect(vec3 o, vec3 d, out float near, out float far)
{
   vec3 ray=normalize(d-o);
   vec3 oToCenter=sphere_center-o;
   // check intersection
   vec3 centerProjOnRay=o+ray*dot(oToCenter,ray);
   float minCenterDistToRay=length(centerProjOnRay-sphere_center);
   if ( (minCenterDistToRay <= sphere_radius) &&
        dot(d-o,normalize(oToCenter))>length(oToCenter)-sphere_radius )
   {
      float sphere_radius_sqr = sphere_radius*sphere_radius;
      float minCenterDistToRaySqr = minCenterDistToRay*minCenterDistToRay;
      float centerProjOnRayToInter = sqrt(sphere_radius_sqr - minCenterDistToRaySqr);
      vec3 nearPt = centerProjOnRay - ray*centerProjOnRayToInter;
      near = length(nearPt-o);
      vec3 farPt = centerProjOnRay + ray*centerProjOnRayToInter;
      far = min(length(d-o),length(farPt-o));
      return true;
   }
   return false;
}

// Applies the filmic curve from John Hable's presentation
// More details at : http://filmicgames.com/archives/75
vec3 ToneMapFilmicALU(vec3 _color)
{
	_color = max(vec3(0), _color - vec3(0.004));
	_color = (_color * (6.2*_color + vec3(0.5))) / (_color * (6.2 * _color + vec3(1.7)) + vec3(0.06));
	return _color;
}

void main( void )
{

   vec2 uv = gl_FragCoord.xy/iResolution.xy;

   // get the resolution
   vec2 iResolution = vec2(adsk_result_w, adsk_result_h);
   // camera position in world (NB : z < 0)
   vec3 ro=camToWorldPos(vec3(0.0));
   // screen space pos of the current fragment
   //vec2 uv = gl_FragCoord.xy/iResolution;
   // fetch the fragment depth
   float depth = texture2D(depth_matte, uv).x;
   // fetch the fragment diffuse color
   vec4  diff = texture2D(front, uv);
   // get the fragment world position (NB : z < 0)
   vec3 pos = camToWorldPos(screenToCamPos(gl_FragCoord.xy,depth));
   // get the ray dir to march along
   vec3 rd=normalize(pos-ro);
   // get the ray length to march along
   float rz=distance(pos,ro);
   // output color initialize to the diffuse
   vec4 col = diff;

   // ld, td: local, total density
   // w: weighting factor
   float ld=0., td=0., w=0.;

   // t: length of the ray
   // d: distance function
   float d=1., t=0.;

   const float h = 0.1;

   vec4 sum = vec4(col.rgb,0.0);

   float min_dist=0.0, max_dist=0.0;

   // does the ray from camera to fragment pass through the exploding sphere ?
   if(RaySphereIntersect(ro, pos, min_dist, max_dist))
   {
      // scale factor to convert from action world space to explosion world space
      float sf = 1.0/200.0;
      vec3 sphereCenterNorm=sphere_center*sf;
      float sphereDiameterNorm=2.0*sphere_radius*sf;
      ro = ro*sf;
      min_dist = min_dist*sf;
      max_dist = max_dist*sf;

      t = min_dist*step(t,min_dist);

      // raymarch loop
      for (int i=0; i<steps ; i++)
      {
         vec3 pos = ro + t*rd;

         // Loop break conditions.
         if(td>0.9 || d<0.12*t || t>10. || sum.a > 0.99 || t>max_dist) break;

         // evaluate distance function
         float d = map(pos-sphereCenterNorm);
         d = abs(d)+0.07;


         // change this string to control density
         d = max(d,0.03);

         // point light calculations
         vec3 ldst = sphereCenterNorm-pos;
         float lDist = max(length(ldst), 0.001);

         sum.rgb+=(lightColor/exp(lDist*lDist*lDist*.08)/30.); // bloom

         if (d<h)
         {
            // compute local density
            ld = h - d;
            // compute weighting factor
            w = (1. - td) * ld;
            // accumulate density
            td += w + 1./200.;
            col += vec4( computeColor(td,lDist), td );
            // emission
            sum += sum.a * vec4(sum.rgb, 0.0) * 0.2 / lDist;
            // uniform scale density
            col.a *= 0.2;
            // colour by alpha
            col.rgb *= col.a;
            // alpha blend in contribution
            sum = sum + col*(1.0 - sum.a);
         }
         td += 1./70.;
         t += max(d * 0.08 * max(min(length(ldst),d),2.0), 0.01);
      }

      sum *= 1. / exp( ld * 0.2 ) * 0.8;
      sum = clamp( sum, 0.0, 1.0 );
      sum.xyz = sum.xyz*sum.xyz*(3.0-2.0*sum.xyz);
      float sphereInfluence = smoothstep(0.0,sphereDiameterNorm,max_dist-min_dist);
      gl_FragColor = mix(diff,vec4(sum.xyz,1.0),sphereInfluence);
   }
   else
   {
      gl_FragColor = col;
   }
}
