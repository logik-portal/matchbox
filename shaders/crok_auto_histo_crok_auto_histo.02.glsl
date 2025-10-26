//*****************************************************************************/
//
// Filename: MultiTargetCustomMipmaps.2.glsl
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
#version 120
#extension GL_ARB_shader_texture_lod : enable
uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1;
uniform sampler2D adsk_results_pass1_1;
uniform sampler2D front;
uniform float max_threshold, min_threshold;
uniform bool clamp_neg, clamp_high;
//-----------------------------------------------------------------------------
//
void main()
{
   vec2 texSize = vec2(adsk_result_w, adsk_result_h);
   vec2 uv = gl_FragCoord.xy/texSize;
   vec4 col = texture2D(front, uv);
   float min_c = texture2DLod(adsk_results_pass1,uv, 10.0).r;
   float max_c = texture2DLod(adsk_results_pass1_1,uv,abs(-10.0)).r;

   // clamp negatives
   if ( clamp_neg ){
     min_c = min_threshold;
   }

   // clamp highlites
   if ( clamp_high ){
     max_c = max_threshold;
   }

   //autoadjust histogram
   col = min(max(col - vec4(min_c), vec4(0.0)) / (vec4(max_c) - vec4(min_c)), 1.0);
   gl_FragColor = vec4(col);
}
