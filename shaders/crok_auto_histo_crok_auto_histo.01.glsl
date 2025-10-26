#version 120
//*****************************************************************************/
//
// Filename: MultiTargetCustomMipmaps.1.glsl
//
// Copyright (c) 2016 Autodesk, Inc.
// All rights reserved.
//
// Use of this software is subject to the terms of the Autodesk license
// agreement provided at the time of installation or download, or which
// otherwise accompanies this software in either electronic or hard copy form.
//*****************************************************************************/

/**
 * @brief Compute a Min MipMap and a Max MipMap
 */
#extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_texture_lod : enable

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D front;
uniform sampler2D adsk_results_pass1;
uniform sampler2D adsk_results_pass1_1;
uniform int adsk_result_level_pass1;

//-----------------------------------------------------------------------------
//
void main()
{
   // size of the first level
   vec2 texSize = vec2(adsk_result_w,adsk_result_h);
   // first level : copy the input depth
   if (adsk_result_level_pass1==0)
   {
      vec2 uv = gl_FragCoord.xy/texSize;
      gl_FragData[0] = texture2D(front,uv);
      gl_FragData[1] = texture2D(front,uv);
      return;
   }
   // map the current pixel to it's corresponding pixel in the previous mip
   int prev_level = (adsk_result_level_pass1-1);
   vec2 levelSize =
      max(vec2(1.0),vec2(ivec2(texSize)>>adsk_result_level_pass1));
   vec2 uv = gl_FragCoord.xy/levelSize;
   vec2 inc = vec2(1.5)/vec2(ivec2(texSize)>>prev_level);

   float v1 = texture2DLod(adsk_results_pass1,
      uv + vec2(inc.x, inc.y),  float(prev_level)).r;
   float v2 = texture2DLod(adsk_results_pass1,
      uv + vec2(-inc.x, inc.y),  float(prev_level)).r;
   float v3 = texture2DLod(adsk_results_pass1,
      uv + vec2(inc.x, -inc.y),  float(prev_level)).r;
   float v4 = texture2DLod(adsk_results_pass1,
      uv + vec2(-inc.x, -inc.y),  float(prev_level)).r;

   // return the min value of the 4 elements of the previous level
   gl_FragData[0] = vec4(vec3(min(min(min(v1,v2),v3),v4)),1.0);

   v1 = texture2DLod(adsk_results_pass1_1,
      uv + vec2(inc.x, inc.y),  float(prev_level)).r;
   v2 = texture2DLod(adsk_results_pass1_1,
      uv + vec2(-inc.x, inc.y),  float(prev_level)).r;
   v3 = texture2DLod(adsk_results_pass1_1,
      uv + vec2(inc.x, -inc.y),  float(prev_level)).r;
   v4 = texture2DLod(adsk_results_pass1_1,
      uv + vec2(-inc.x, -inc.y),  float(prev_level)).r;

   // return the max value of the 4 elements of the previous level
   gl_FragData[1] = vec4(vec3(max(max(max(v1,v2),v3),v4)),1.0);
}
