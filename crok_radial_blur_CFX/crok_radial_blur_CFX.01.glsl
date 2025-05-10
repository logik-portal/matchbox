#version 120
/*
	Full Scene Radial Blur
	----------------------

	Radial blur - as a postprocessing effect - is one of the first things I considered doing
	when the multipass system came out. I've always loved this effect. Reminds me of the early
	demos from Aardbei et al.

	Anyway, Shadertoy user, Passion, did a really cool radial blur on a field of spheres that
	inspired me to do my own. Radial blurs are pretty straight forward, but it was still
  helpful to have Passion's version as a guide.

  As for the radial blur process, there's not much to it. Start off at the pixel position,
  then radiate outwards gathering up pixels with decreased weighting. The result is a
	blurring of the image in a radial fashion, strangely enough. :)

	Inspired by:

	Blue Dream - Passion
	https://www.shadertoy.com/view/MdG3RD

	Radial Blur - IQ
	https://www.shadertoy.com/view/4sfGRn

	Rays of Blinding Light - mu6k
	https://www.shadertoy.com/view/lsf3Dn

*/

// The radial blur section. Shadertoy user, Passion, did a good enough job, so I've used a
// slightly trimmed down version of that. By the way, there are accumulative weighting
// methods that do a slightly better job, but this method is good enough for this example.
// based on https://www.shadertoy.com/view/XsKGRW by Shane


uniform sampler2D front, depth_matte;
uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 iResolution = vec2(adsk_result_w, adsk_result_h);
uniform vec3 light_pos;
uniform float decay, density, f_weigth;

// Radial blur samples. More is always better, but there's frame rate to consider.
uniform float SAMPLES; // 24.;


// 2x1 hash. Used to jitter the samples.
float hash( vec2 p ){ return fract(sin(dot(p, vec2(41, 289)))*45758.5453); }


// Light offset.
//
// I realized, after a while, that determining the correct light position doesn't help, since
// radial blur doesn't really look right unless its focus point is within the screen boundaries,
// whereas the light is often out of frame. Therefore, I decided to go for something that at
// least gives the feel of following the light. In this case, I normalized the light position
// and rotated it in unison with the camera rotation. Hacky, for sure, but who's checking? :)
vec3 lOff(){

    vec2 u = vec2(0.5);
    mat2 a = mat2(u, -u.y, u.x);

    vec3 l = normalize(light_pos);
    l.xz = l.xz;
    l.xy = l.xy;

    return l;

}



void main( void )
{
    // Screen coordinates.
    vec2 uv = gl_FragCoord.xy / iResolution.xy;

    // Radial blur factors.
    //
    // Falloff, as we radiate outwards.
    //float decay = 0.97;
    // Controls the sample density, which in turn, controls the sample spread.
    //float density = 0.5;
    // Sample weight. Decays as we radiate outwards.
    float weight = f_weigth *0.01;

    // Light offset. Kind of fake. See above.
    vec3 l = lOff();

    // Offset texture position (uv - .5), offset again by the fake light movement.
    // It's used to set the blur direction (a direction vector of sorts), and is used
    // later to center the spotlight.
    //
    // The range is centered on zero, which allows the accumulation to spread out in
    // all directions. Ie; It's radial.
    vec2 tuv =  uv - .5 - l.xy*.45;

    // Dividing the direction vector above by the sample number and a density factor
    // which controls how far the blur spreads out. Higher density means a greater
    // blur radius.
    vec2 dTuv = tuv*density/SAMPLES;

    // Grabbing a portion of the initial texture sample. Higher numbers will make the
    // scene a little clearer, but I'm going for a bit of abstraction.
    //vec4 col = texture2D(front, uv.xy)*0.25;
    vec4 col = vec4(0.0);

    // The radial blur loop. Take a texture sample, move a little in the direction of
    // the radial direction vector (dTuv) then take another, slightly less weighted,
    // sample, add it to the total, then repeat the process until done.
    for(float i=0.; i < SAMPLES; i++){

        uv -= dTuv;
        col += texture2D(front, uv) * weight;
        weight *= (decay + 90.0) * 0.01;

    }

    // Multiplying the final color with a spotlight centered on the focal point of the radial
    // blur. It's a nice finishing touch... that Passion came up with. If it's a good idea,
    // it didn't come from me. :)
    //col *= (1. - dot(tuv, tuv)*.75);

    // Smoothstepping the final color, just to bring it out a bit.
    gl_FragColor = smoothstep(0., 1., col);
}
