// KE Additive Dissolve v1.0
// Created by Ted Stanley (KuleshovEffect) October 2025
// With help from Claude

#version 430
layout ( location = 0 ) out vec4 fragColor;

layout( binding = 1 ) uniform AdskUniformBlock
{
   float adsk_result_w;
   float adsk_result_h;
};

layout( binding = 3 ) uniform sampler2D front1;   // outgoing
layout( binding = 4 ) uniform sampler2D front2;   // incoming
layout( binding = 5 ) uniform sampler2D matte1;
layout( binding = 6 ) uniform sampler2D matte2;

layout( binding = 2 ) uniform UniformBlock
{
   float transp;      // 1 = all front1, 0 = all front2
   float overlap;     // 1.0 = plain crossfade, 2.0 = full additive
   bool  useLinear;   // do the math in linear light
   float gammaVal;    // ~2.2 for display-referred footage
   float gain;        // trim on the result
};

vec3 toLin( vec3 c )   { return pow( max( c, vec3(0.0) ), vec3( gammaVal ) ); }
vec3 fromLin( vec3 c ) { return pow( max( c, vec3(0.0) ), vec3( 1.0 / gammaVal ) ); }

void main()
{
   vec2 coords = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );

   vec4 a = vec4( texture( front1, coords ).rgb, texture( matte1, coords ).b ); // outgoing
   vec4 b = vec4( texture( front2, coords ).rgb, texture( matte2, coords ).b ); // incoming

   if ( useLinear ) {
      a.rgb = toLin( a.rgb );
      b.rgb = toLin( b.rgb );
   }

   // transp runs 1 -> 0 as the incoming shot takes over, so incoming progress is 1 - transp
   float wA = min( 1.0, transp * overlap );
   float wB = min( 1.0, ( 1.0 - transp ) * overlap );

   vec3 rgb = ( a.rgb * wA + b.rgb * wB ) * gain;
   float alpha = min( 1.0, a.a * wA + b.a * wB );

   if ( useLinear ) rgb = fromLin( rgb );

   fragColor = vec4( rgb, alpha );
}