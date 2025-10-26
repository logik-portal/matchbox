#version 120
// based on www.shadertoy.com/view/4sKBWR by demofox
/*
This shadertoy was adapted from paniq's at https://www.shadertoy.com/view/MsGfDz
He is on twitter at: https://twitter.com/paniq
Paniq is truly a king among men.

He totally didn't demand i put that here when i credited him, I promise (;

Items of note!

* The blue noise texture sampling should be set to "nearest" (not mip map!) and repeat

* you should calculate the uv to use based on the pixel coordinate and the size of the blue noise texture.
 * aka you should tile the blue noise texture across the screen.
 * blue nois actually tiles really well unlike white noise.

* A blue noise texture is "low discrepancy over space" which means there are fewer visible patterns than white noise
 * it also gives more even coverage vs white noise. no clumps or voids.

* In an attempt to make it also blue noise over time, you can add the golden ratio and frac it.
 * that makes it lower discrepancy over time, but makes it less good over space.
 * thanks to r4unit for that tip! https://twitter.com/R4_Unit

* Animating the noise in this demo makes the noise basically disappear imo, it's really nice!

For more information:

What the heck is blue nois:
https://blog.demofox.org/2018/01/30/what-the-heck-is-blue-noise/

Low discrepancy sequences:
https://blog.demofox.org/2017/05/29/when-random-numbers-are-too-random-low-discrepancy-sequences/

You can get your own blue noise textures here:
http://momentsingraphics.de/?p=127
*/
uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform sampler2D adsk_results_pass1, front;
uniform float time;
float iTime = adsk_time *.05 * time;
const float c_goldenRatioConjugate = 0.61803398875;

uniform bool ANIMATE_NOISE; //0
uniform int TARGET_BITS; //4  // dithered to this many bits
uniform bool DITHER_IN_LINEAR_SPACE; // 0
uniform bool show_only_noise;

void main()
{
    vec2 uv = gl_FragCoord.xy/res.xy;
    vec3 fg = texture2D( front, uv ).rgb;
    vec3 col = vec3(0.0);
    // get blue noise "random" number
    vec2 blueNoiseUV = gl_FragCoord.xy / vec2(1024.0);
    vec3 blueNoise = texture2D(adsk_results_pass1, blueNoiseUV).rgb;
    if ( ANIMATE_NOISE )
      blueNoise = fract(blueNoise + float(iTime) * c_goldenRatioConjugate);

    // dither to the specified number of bits, using sRGB conversions if desired
    if( DITHER_IN_LINEAR_SPACE )
    	fg = pow(fg, vec3(2.2));

    float scale = exp2(float(TARGET_BITS)) - 1.0;
    col = floor(fg*scale + blueNoise)/scale;

    if( DITHER_IN_LINEAR_SPACE )
    	col = pow(col, 1.0/vec3(2.2));

    if ( show_only_noise )
      col = blueNoise;

    gl_FragColor = vec4(col,1.0);
}
