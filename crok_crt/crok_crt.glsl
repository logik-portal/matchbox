#version 120
// based on https://www.shadertoy.com/view/MtSfRK by TimothyLottes

uniform sampler2D source;
uniform float adsk_result_w, adsk_result_h, adsk_source_w, adsk_source_h;
vec2 iResolution = vec2(adsk_result_w, adsk_result_h);

uniform bool warp_enable, vignette_enable;
uniform float warp, reso, vignette_amount;

#define CRTS_WARP

// Try different masks
uniform int mask_grille;
//#define CRTS_MASK_NONE
//#define CRTS_MASK_GRILLE_LITE
//#define CRTS_MASK_GRILLE
//#define CRTS_MASK_SHADOW
//--------------------------------------------------------------
// Since shadertoy doesn't have sRGB textures
// And we need linear input into shader
// Don't do this in your code
float FromSrgb1(float c){
 return (c<=0.04045)?c*(1.0/12.92):
  pow(c*(1.0/1.055)+(0.055/1.055),2.4);}
//--------------------------------------------------------------
vec3 FromSrgb(vec3 c){return vec3(
 FromSrgb1(c.r),FromSrgb1(c.g),FromSrgb1(c.b));}
//--------------------------------------------------------------
// Scanline thinness
//  0.50 = fused scanlines
//  0.70 = recommended default
//  1.00 = thinner scanlines (too thin)
uniform float INPUT_THIN; // 0.70
//--------------------------------------------------------------
// Horizonal scan blur
//  -3.0 = pixely
//  -2.5 = default
//  -2.0 = smooth
//  -1.0 = too blurry
uniform float INPUT_BLUR; // -2.5
//--------------------------------------------------------------
// Shadow mask effect, ranges from,
//  0.25 = large amount of mask (not recommended, too dark)
//  0.50 = recommended default
//  1.00 = no shadow mask
uniform float INPUT_MASK; //0.5
//--------------------------------------------------------------
//#define INPUT_X 128.0
//#define INPUT_Y 54.0
float INPUT_X = adsk_result_w / reso;
float INPUT_Y = adsk_result_h / reso;

//--------------------------------------------------------------

// Setup the function which returns input image color
vec3 CrtsFetch(vec2 uv){
 return FromSrgb(texture2D(source,uv.xy).rgb);}

  #define CrtsF1 float
  #define CrtsF2 vec2
  #define CrtsF3 vec3
  #define CrtsF4 vec4
  #define CrtsFractF1 fract
  #define CrtsRcpF1(x) (1.0/(x))
  #define CrtsSatF1(x) clamp((x),0.0,1.0)
//--------------------------------------------------------------
  CrtsF1 CrtsMax3F1(CrtsF1 a,CrtsF1 b,CrtsF1 c){
   return max(a,max(b,c));}

//==============================================================
 //_____________________________/\_______________________________
//==============================================================
//              TONAL CONTROL CONSTANT GENERATION
//--------------------------------------------------------------
// This is in here for rapid prototyping
// Please use the CPU code and pass in as constants
//==============================================================
 CrtsF4 CrtsTone(
 CrtsF1 contrast,
 CrtsF1 saturation,
 CrtsF1 thin,
 CrtsF1 mask){
//--------------------------------------------------------------
  if (mask_grille == 0)
     mask=1.0;
//--------------------------------------------------------------
  if (mask_grille == 1)
  {
    // Normal R mask is {1.0,mask,mask}
    // LITE   R mask is {mask,1.0,1.0}
    mask=0.5+mask*0.5;
  }

//--------------------------------------------------------------
  CrtsF4 ret;
  CrtsF1 midOut=0.18/((1.5-thin)*(0.5*mask+0.5));
  CrtsF1 pMidIn=pow(0.18,contrast);
  ret.x=contrast;
  ret.y=((-pMidIn)+midOut)/((1.0-pMidIn)*midOut);
  ret.z=((-pMidIn)*midOut+pMidIn)/(midOut*(-pMidIn)+midOut);
  ret.w=contrast+saturation;
  return ret;}
//_____________________________/\_______________________________
//==============================================================
//                            MASK
//--------------------------------------------------------------
// Letting LCD/OLED pixel elements function like CRT phosphors
// So "phosphor" resolution scales with display resolution
//--------------------------------------------------------------
// Not applying any warp to the mask (want high frequency)
// Real aperture grille has a mask which gets wider on ends
// Not attempting to be "real" but instead look the best
//--------------------------------------------------------------
// Shadow mask is stretched horizontally
//  RRGGBB
//  GBBRRG
//  RRGGBB
// This tends to look better on LCDs than vertical
// Also 2 pixel width is required to get triad centered
//--------------------------------------------------------------
// The LITE version of the Aperture Grille is brighter
// Uses {dark,1.0,1.0} for R channel
// Non LITE version uses {1.0,dark,dark}
//--------------------------------------------------------------
// 'pos' - This is 'fragCoord.xy'
//         Pixel {0,0} should be {0.5,0.5}
//         Pixel {1,1} should be {1.5,1.5}
//--------------------------------------------------------------
// 'dark' - Exposure of of masked channel
//          0.0=fully off, 1.0=no effect
//==============================================================
 CrtsF3 CrtsMask(CrtsF2 pos,CrtsF1 dark){
  if (mask_grille == 2)
  {
    CrtsF3 m=CrtsF3(dark,dark,dark);
    CrtsF1 x=CrtsFractF1(pos.x*(1.0/3.0));
    if(x<(1.0/3.0))m.r=1.0;
    else if(x<(2.0/3.0))m.g=1.0;
    else m.b=1.0;
    return m;
  }

//--------------------------------------------------------------
  if (mask_grille == 1)
  {
    CrtsF3 m=CrtsF3(1.0,1.0,1.0);
    CrtsF1 x=CrtsFractF1(pos.x*(1.0/3.0));
    if(x<(1.0/3.0))m.r=dark;
    else if(x<(2.0/3.0))m.g=dark;
    else m.b=dark;
    return m;
  }

//--------------------------------------------------------------
  if (mask_grille == 0)
   return CrtsF3(1.0,1.0,1.0);
//--------------------------------------------------------------
  if (mask_grille == 3)
  {
    pos.x+=pos.y*3.0;
    CrtsF3 m=CrtsF3(dark,dark,dark);
    CrtsF1 x=CrtsFractF1(pos.x*(1.0/6.0));
    if(x<(1.0/3.0))m.r=1.0;
    else if(x<(2.0/3.0))m.g=1.0;
    else m.b=1.0;
    return m;
  }
 }
//_____________________________/\_______________________________
//==============================================================
//                        FILTER ENTRY
//--------------------------------------------------------------
// Input must be linear
// Output color is linear
//--------------------------------------------------------------
// Must have fetch function setup: CrtsF3 CrtsFetch(CrtsF2 uv)
//  - The 'uv' range is {0.0 to 1.0} for input texture
//  - Output of this must be linear color
//--------------------------------------------------------------
// SCANLINE MATH & AUTO-EXPOSURE NOTES
// ===================================
// Each output line has contribution from at most 2 scanlines
// Scanlines are shaped by a windowed cosine function
// This shape blends together well with only 2 lines of overlap
//--------------------------------------------------------------
// Base scanline intensity is as follows
// which leaves output intensity range from {0 to 1.0}
// --------
// thin := range {thick 0.5 to thin 1.0}
// off  := range {0.0 to <1.0},
//         sub-pixel offset between two scanlines
//  --------
//  a0=cos(min(0.5,     off *thin)*2pi)*0.5+0.5;
//  a1=cos(min(0.5,(1.0-off)*thin)*2pi)*0.5+0.5;
//--------------------------------------------------------------
// This leads to a image darkening factor of roughly:
//  {(1.5-thin)/1.0}
// This is further reduced by the mask:
//  {1.0/2.0+mask*1.0/2.0}
// Reciprocal of combined effect is used for auto-exposure
//  to scale up the mid-level in the tonemapper
//==============================================================
 CrtsF3 CrtsFilter(
//--------------------------------------------------------------
  // SV_POSITION, fragCoord.xy
  CrtsF2 ipos,
//--------------------------------------------------------------
  // inputSize / outputSize (in pixels)
  CrtsF2 inputSizeDivOutputSize,
//--------------------------------------------------------------
  // 0.5 * inputSize (in pixels)
  CrtsF2 halfInputSize,
//--------------------------------------------------------------
  // 1.0 / inputSize (in pixels)
  CrtsF2 rcpInputSize,
//--------------------------------------------------------------
  // 1.0 / outputSize (in pixels)
  CrtsF2 rcpOutputSize,
//--------------------------------------------------------------
  // 2.0 / outputSize (in pixels)
  CrtsF2 twoDivOutputSize,
//--------------------------------------------------------------
  // inputSize.y
  CrtsF1 inputHeight,
//--------------------------------------------------------------
  // Warp scanlines but not phosphor mask
  //  0.0 = no warp
  //  1.0/64.0 = light warping
  //  1.0/32.0 = more warping
  // Want x and y warping to be different (based on aspect)
  CrtsF2 warp,
//--------------------------------------------------------------
  // Scanline thinness
  //  0.50 = fused scanlines
  //  0.70 = recommended default
  //  1.00 = thinner scanlines (too thin)
  // Shared with CrtsTone() function
  CrtsF1 thin,
//--------------------------------------------------------------
  // Horizonal scan blur
  //  -3.0 = pixely
  //  -2.5 = default
  //  -2.0 = smooth
  //  -1.0 = too blurry
  CrtsF1 blur,
//--------------------------------------------------------------
  // Shadow mask effect, ranges from,
  //  0.25 = large amount of mask (not recommended, too dark)
  //  0.50 = recommended default
  //  1.00 = no shadow mask
  // Shared with CrtsTone() function
  CrtsF1 mask,
//--------------------------------------------------------------
  // Tonal curve parameters generated by CrtsTone()
  CrtsF4 tone
//--------------------------------------------------------------
 ){

  // Optional apply warp
  CrtsF2 pos;
   // Convert to {-1 to 1} range
   pos=ipos*twoDivOutputSize-CrtsF2(1.0,1.0);
   // Distort pushes image outside {-1 to 1} range
   pos*=CrtsF2(
    1.0+(pos.y*pos.y)*warp.x,
    1.0+(pos.x*pos.x)*warp.y);
   // TODO: Vignette needs optimization
   float vig_en = 0.0;
   if (vignette_enable)
   vig_en = 1.0;
   CrtsF1 vin=1.0 * vig_en-((1.0-CrtsSatF1(pos.x*pos.x))*(1.0-CrtsSatF1(pos.y*pos.y)));

   vin=CrtsSatF1((-vin)*inputHeight+inputHeight);
   // Leave in {0 to inputSize}
   pos=pos*halfInputSize+halfInputSize;
//--------------------------------------------------------------
  // Snap to center of first scanline
  CrtsF1 y0=floor(pos.y-0.5)+0.5;
   // Snap to center of one of four pixels
   CrtsF1 x0=floor(pos.x-1.5)+0.5;
   // Inital UV position
   CrtsF2 p=CrtsF2(x0*rcpInputSize.x,y0*rcpInputSize.y);
   // Fetch 4 nearest texels from 2 nearest scanlines
   CrtsF3 colA0=CrtsFetch(p);
   p.x+=rcpInputSize.x;
   CrtsF3 colA1=CrtsFetch(p);
   p.x+=rcpInputSize.x;
   CrtsF3 colA2=CrtsFetch(p);
   p.x+=rcpInputSize.x;
   CrtsF3 colA3=CrtsFetch(p);
   p.y+=rcpInputSize.y;
   CrtsF3 colB3=CrtsFetch(p);
   p.x-=rcpInputSize.x;
   CrtsF3 colB2=CrtsFetch(p);
   p.x-=rcpInputSize.x;
   CrtsF3 colB1=CrtsFetch(p);
   p.x-=rcpInputSize.x;
   CrtsF3 colB0=CrtsFetch(p);

//--------------------------------------------------------------
  // Vertical filter
  // Scanline intensity is using sine wave
  // Easy filter window and integral used later in exposure
  CrtsF1 off=pos.y-y0;
  CrtsF1 pi2=6.28318530717958;
  CrtsF1 hlf=0.5;
  CrtsF1 scanA=cos(min(0.5,  off *thin     )*pi2)*hlf+hlf;
  CrtsF1 scanB=cos(min(0.5,(-off)*thin+thin)*pi2)*hlf+hlf;
//--------------------------------------------------------------

   // Horizontal kernel is simple gaussian filter
   CrtsF1 off0=pos.x-x0;
   CrtsF1 off1=off0-1.0;
   CrtsF1 off2=off0-2.0;
   CrtsF1 off3=off0-3.0;
   CrtsF1 pix0=exp2(blur*off0*off0);
   CrtsF1 pix1=exp2(blur*off1*off1);
   CrtsF1 pix2=exp2(blur*off2*off2);
   CrtsF1 pix3=exp2(blur*off3*off3);
   CrtsF1 pixT=CrtsRcpF1(pix0+pix1+pix2+pix3);

    // Get rid of wrong pixels on edge
    pixT *=vin;

   scanA *=pixT;
   scanB *=pixT;
   // Apply horizontal and vertical filters
   CrtsF3 color=
    (colA0*pix0+colA1*pix1+colA2*pix2+colA3*pix3)*scanA +
    (colB0*pix0+colB1*pix1+colB2*pix2+colB3*pix3)*scanB;

  // Apply phosphor mask
  color*=CrtsMask(ipos,mask);
  // Optional color processing
  // Tonal control, start by protecting from /0
  CrtsF1 peak=max(1.0/(256.0*65536.0),
  CrtsMax3F1(color.r,color.g,color.b));
  // Compute the ratios of {R,G,B}
  CrtsF3 ratio=color*CrtsRcpF1(peak);
  // Apply tonal curve to peak value
  peak=pow(peak,tone.x);
  peak=peak*CrtsRcpF1(peak*tone.y+tone.z);
  // Apply saturation
  ratio=pow(ratio,CrtsF3(tone.w,tone.w,tone.w));
  // Reconstruct color
  return ratio*peak;
  }

// Convert from linear to sRGB
float ToSrgb1(float c){
 return(c<0.0031308?c*12.92:1.055*pow(c,0.41666)-0.055);}
//--------------------------------------------------------------
vec3 ToSrgb(vec3 c){return vec3(
 ToSrgb1(c.r),ToSrgb1(c.g),ToSrgb1(c.b));}
//--------------------------------------------------------------
void main()
{
  gl_FragColor.rgb=CrtsFilter(
  gl_FragCoord.xy,
  vec2(INPUT_X,INPUT_Y)/iResolution.xy,
  vec2(INPUT_X,INPUT_Y)*vec2(0.5,0.5),
  1.0/vec2(INPUT_X,INPUT_Y),
  1.0/iResolution.xy,
  2.0/iResolution.xy,
  INPUT_Y,
  vec2(1.0/48.0 * warp,1.0/24.0 *warp),
  INPUT_THIN * - 1.0,
  INPUT_BLUR - 6.0,
  1.0 - INPUT_MASK,
  CrtsTone(1.0,0.0,INPUT_THIN,INPUT_MASK));
  gl_FragColor = vec4(ToSrgb(gl_FragColor.rgb), 1.0);
}
