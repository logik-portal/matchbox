//*****************************************************************************/
//
// Filename: DustLens.1.glsl
//
// Copyright (c) 2015 Autodesk, Inc.
// All rights reserved.
//
// This computer source code and related instructions and comments are the
// unpublished confidential and proprietary information of Autodesk, Inc.
// and are protected under applicable copyright and trade secret law.
// They may not be disclosed to, copied or used by any third party without
// the prior written consent of Autodesk, Inc.
//*****************************************************************************/

//------------------------------------------------------------------------------
// Input and texture grid variables
//------------------------------------------------------------------------------
uniform sampler2D source;
uniform vec2 sel;
// uniform int textureSelector;
int textureSelector;
uniform float     adsk_result_w, adsk_result_h, p1, p2;
uniform sampler2D adsk_texture_grid;
uniform bool preset_selector;

//4x4 grid
const float       tileDimensionX = 2000.0;
const float       tileDimensionY = 2000.0;
const float       gridDimensionX = 8000.0;
const float       gridDimensionY = 8000.0;
const int         textureNum = int((gridDimensionX/tileDimensionX) *
                                   (gridDimensionY/tileDimensionY));

const int         texturePerCol = int(gridDimensionX / tileDimensionX);
const int         texturePerRow = int(gridDimensionY / tileDimensionY);

vec3 screen( vec3 s, vec3 d )
{
	return s + d - s * d;
}

//------------------------------------------------------------------------------
// Utilitary functions
//------------------------------------------------------------------------------
// Utilitary functions to get a textureGrid tile based on an int value
// 12 - 13 - 14 - 15
// 8  -  9 - 10 - 11
// 4  -  5 - 6  - 7
// 0  -  1 - 2  - 3


//return a pixel from a tile of the texture grid
//pixelX and pixelY = [0,1]
vec4 getGridTile(float tileNum, vec2 position)
{

   vec2 tile = vec2(tileNum/(gridDimensionY/tileDimensionY), mod(tileNum, (gridDimensionX/tileDimensionX)));

   float szTileX = tileDimensionX/gridDimensionX;
   float szTileY = tileDimensionX/gridDimensionX;

   vec2 posGrid = vec2((floor(tile.x) * tileDimensionX / gridDimensionX) +
                       (position.x * tileDimensionX / gridDimensionX),
                       (floor(tile.y) * tileDimensionY / gridDimensionY) +
                       (position.y * tileDimensionY / gridDimensionY));

					   if ( position.x  > 1.0 ||
					        position.x * szTileX  < 0.0 ||
					        position.y   > 1.0 ||
					        position.y * szTileY   < 0.0 || tileNum < 0.0)
					   {
					      return  vec4(0.0, 0.0, 0.0, 0.0);
					   }
					   else
					   {

					      return texture2D( adsk_texture_grid, posGrid );
					   }
	}


//------------------------------------------------------------------------------
// MAIN
//------------------------------------------------------------------------------
void main()
{
 vec2 resolution = vec2(adsk_result_w, adsk_result_h);
 vec2 position = vec2(gl_FragCoord.xy / resolution.xy);
 vec2 uv = vec2(gl_FragCoord.xy / resolution.xy);
 vec2 uv_sel1 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -15.0);
 vec2 uv_sel2 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -14.0);
 vec2 uv_sel3 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -13.0);
 vec2 uv_sel4 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -12.0);
 vec2 uv_sel5 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -11.0);
 vec2 uv_sel6 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -10.0);
 vec2 uv_sel7 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -9.0);
 vec2 uv_sel8 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -8.0);
 vec2 uv_sel9 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -7.0);
 vec2 uv_sel10 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -6.0);
 vec2 uv_sel11 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -5.0);
 vec2 uv_sel12 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -4.0);
 vec2 uv_sel13 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -3.0);
 vec2 uv_sel14 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -2.0);
 vec2 uv_sel15 = vec2((gl_FragCoord.xy / resolution.xy) * 16.0) + vec2(-15.0, -1.0);
	float lb = ((adsk_result_w / 1.2) / adsk_result_h);

   vec4 front = texture2D(source, uv);
   vec4 col = vec4(0.0);
	  textureSelector = 0;
   if ( sel.y > 0.125 )
	  textureSelector = 1;
   if ( sel.y > 0.1875 )
	  textureSelector = 2;
   if ( sel.y > 0.25 )
	  textureSelector = 3;
   if ( sel.y > 0.3125 )
	  textureSelector = 4;
   if ( sel.y > 0.375 )
    textureSelector = 5;
   if ( sel.y > 0.4375 )
    textureSelector = 6;
   if ( sel.y > 0.5 )
    textureSelector = 7;
   if ( sel.y > 0.5625 )
    textureSelector = 8;
   if ( sel.y > 0.625 )
    textureSelector = 9;
   if ( sel.y > 0.6875 )
    textureSelector = 10;
   if ( sel.y > 0.75 )
    textureSelector = 11;
   if ( sel.y > 0.8125 )
    textureSelector = 13;
   if ( sel.y > 0.875 )
    textureSelector = 14;
   if ( sel.y > 0.9375 )
    textureSelector = 15;

   float tileNum = float(textureSelector);
   vec4 v_sel = getGridTile(float(15), uv_sel1);
   v_sel += getGridTile(float(14), uv_sel2);
   v_sel += getGridTile(float(13), uv_sel3);
   v_sel += getGridTile(float(11), uv_sel4);
   v_sel += getGridTile(float(10), uv_sel5);
   v_sel += getGridTile(float(9), uv_sel6);
   v_sel += getGridTile(float(8), uv_sel7);
   v_sel += getGridTile(float(7), uv_sel8);
   v_sel += getGridTile(float(6), uv_sel9);
   v_sel += getGridTile(float(5), uv_sel10);
   v_sel += getGridTile(float(4), uv_sel11);
   v_sel += getGridTile(float(3), uv_sel12);
   v_sel += getGridTile(float(2), uv_sel13);
   v_sel += getGridTile(float(1), uv_sel14);
   v_sel += getGridTile(float(0), uv_sel15);
   vec4 flare = getGridTile(tileNum, position );

   col.rgb = screen(col.rgb, flare.rgb);

   if ( preset_selector )
   {
	   float dist_x = length(uv.x - 0.1);
	   float letterbox = smoothstep(lb, lb, dist_x);
	   col.rgb = mix(col.rgb, vec3(0.0), letterbox);
	   col.rgb = screen(v_sel.rgb, col.rgb);
	   }

   gl_FragColor = col;
}
