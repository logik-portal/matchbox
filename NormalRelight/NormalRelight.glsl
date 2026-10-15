//*****************************************************************************/
//
// NormalRelight.glsl  -  FlameLab, v3 2026-10-13
//
// Normal map ve/veya depth ile Front'u yeniden aydinlatir, normal yonune / derinlige
// gore matte uretir, normal haritasini duzeltir.
//
// Girdiler : Front  = plate (albedo olarak kullanilir)
//            Normal = kamera uzayi normal haritasi (opsiyonel; Normal Source = From Depth ise gerekmez)
//            Matte  = efektin uygulanacagi alan (bagli degilse beyaz)
//            Depth  = derinlik (opsiyonel; Depth Mode = Off ise kullanilmaz)
// Normal kurali (duzeltmeden sonra): +X sag, +Y yukari, +Z kameraya dogru.
// Depth acikken isiklar gercek 3B konumda (metre) hesaplanir ve temas golgesi uretilir.
//
//*****************************************************************************/
#version 430
layout ( location = 0 ) out vec4 fragColor;

layout( binding = 1 ) uniform AdskUniformBlock
{
   float adsk_result_w;
   float adsk_result_h;
};

layout( binding = 3 ) uniform sampler2D front;
layout( binding = 4 ) uniform sampler2D normalTex;
layout( binding = 5 ) uniform sampler2D matte;
layout( binding = 6 ) uniform sampler2D depthTex;

layout( binding = 2 ) uniform UniformBlock
{
   // --- Normal ---
   int   nSource;        // 0: normal map, 1: depth'ten turet
   int   nEncoding;      // 0: 0..1 kodlu (PNG/video), 1: -1..1 ham (EXR float)
   int   nConvention;    // 0: OpenGL (+Y yukari), 1: DirectX (+Y asagi)
   int   nSwizzle;       // 0 XYZ, 1 XZY, 2 YXZ, 3 YZX, 4 ZXY, 5 ZYX
   bool  nFlipX;
   bool  nFlipY;
   bool  nFlipZ;
   float nRotX;          // derece
   float nRotY;
   float nRotZ;
   float nSmooth;        // piksel

   // --- Depth ---
   int   dMode;          // 0 Kapali, 1 Metrik (metre), 2 Depth 0..1 (yakin=koyu), 3 Disparity 0..1 (yakin=parlak)
   float dScale;         // metrik carpan
   float dNear;          // metre (mod 2/3)
   float dFar;
   float dFocal;         // mm
   float dFilmback;      // mm (yatay)
   float sAmt;           // temas golgesi
   float sLen;           // metre
   float sThick;         // metre
   float sBias;          // metre

   // --- Key isik ---
   bool  kOn;
   int   kMode;        // 0: Ikon (nokta isik), 1: Acilar (yonlu isik)
   vec2  kPos;         // viewer ikonu, 0..1 kare koordinati
   float kHeight;      // depth kapali: kare-yuksekligi birimi; acik: ikonun altindaki yuzeyden kameraya metre
   float kFalloff;     // mesafe zayiflamasi
   float kAz;
   float kEl;
   vec3  kCol;
   float kInt;
   float kWrap;
   float kSpec;
   float kGloss;

   // --- Fill / Rim isik ---
   bool  fOn;
   int   fMode;
   vec2  fPos;
   float fHeight;
   float fFalloff;
   float fAz;
   float fEl;
   vec3  fCol;
   float fInt;
   float fWrap;
   float fSpec;
   float fGloss;

   // --- Ambient + Fresnel rim ---
   vec3  aCol;
   float aInt;
   vec3  rimCol;
   float rimInt;
   float rimPower;

   // --- Cikti ---
   int   outMode;        // 0 Sonuc, 1 Isik pasi, 2 Diffuse, 3 Specular, 4 Maske, 5 Duzeltilmis normal, 6 Depth, 7 Golge
   int   blendMode;      // 0 Isik ekle, 1 Isigi degistir, 2 Screen
   int   colourSpace;    // 0 Lineer, 1 Log (Cineon), 2 Video (gamma 2.2)
   float mixAmt;

   // --- Maske ---
   int   maskMode;       // 0 Yon, 1 Kameraya donuk, 2 Kenar (fresnel), 3 Key isik, 4 Fill isik, 5 Derinlik (metre)
   float mAz;
   float mEl;
   float mLow;
   float mHigh;
   float mGamma;
   bool  mInvert;
};

vec3 adsk_scene2log( vec3 lin );
vec3 adsk_log2scene( vec3 log );

const float DEG = 0.017453292519943295;
const int SHADOW_STEPS = 24;

vec3 toLinear( vec3 c )
{
   if ( colourSpace == 1 ) return adsk_log2scene( c );
   if ( colourSpace == 2 ) return sign( c ) * pow( abs( c ), vec3( 2.2 ) );
   return c;
}

vec3 fromLinear( vec3 c )
{
   if ( colourSpace == 1 ) return adsk_scene2log( c );
   if ( colourSpace == 2 ) return sign( c ) * pow( abs( c ), vec3( 1.0 / 2.2 ) );
   return c;
}

// Azimut 0 = kameradan, +90 = sagdan, 180 = arkadan; yukseklik +90 = yukaridan.
vec3 dirFromAngles( float az, float el )
{
   float a = az * DEG;
   float e = el * DEG;
   return normalize( vec3( sin( a ) * cos( e ), sin( e ), cos( a ) * cos( e ) ) );
}

// ------------------------------------------------------------------ depth
bool depthOn() { return dMode != 0; }

float depthAt( vec2 uv )
{
   float v = texture( depthTex, uv ).r;
   float z;
   if ( dMode == 2 )      z = mix( dNear, dFar, v );
   else if ( dMode == 3 ) z = 1.0 / mix( 1.0 / max( dFar, 1e-3 ), 1.0 / max( dNear, 1e-3 ), clamp( v, 0.0, 1.0 ) );
   else                   z = v * dScale;
   return max( z, 1e-3 );
}

// kamera uzayi olcekleri: x = (u-0.5)*fx*Z, y = (v-0.5)*fy*Z, z = -Z
vec2 camScale()
{
   float fx = max( dFilmback, 1e-3 ) / max( dFocal, 1e-3 );
   return vec2( fx, fx * adsk_result_h / adsk_result_w );
}

vec3 camPos( vec2 uv, float z )
{
   return vec3( ( uv - 0.5 ) * camScale() * z, -z );
}

vec2 project( vec3 q )
{
   float z = max( -q.z, 1e-4 );
   return q.xy / ( camScale() * z ) + 0.5;
}

// ------------------------------------------------------------------ normaller
vec3 decodeRaw( vec2 uv )
{
   vec3 v = texture( normalTex, uv ).rgb;
   return nEncoding == 0 ? v * 2.0 - 1.0 : v;
}

vec3 smoothedRaw( vec2 uv )
{
   if ( nSmooth <= 0.0 ) return decodeRaw( uv );
   // 9x9 gauss, yaricap nSmooth pikseli kaplayacak sekilde seyrek ornekleme
   vec2 stp = vec2( nSmooth / 4.0 ) / vec2( adsk_result_w, adsk_result_h );
   vec3 sum = vec3( 0.0 );
   float wsum = 0.0;
   for ( int j = -4; j <= 4; ++j )
   {
      for ( int i = -4; i <= 4; ++i )
      {
         float w = exp( -float( i * i + j * j ) / 8.0 );
         sum += decodeRaw( uv + vec2( i, j ) * stp ) * w;
         wsum += w;
      }
   }
   return sum / wsum;
}

vec3 applySwizzle( vec3 v )
{
   if ( nSwizzle == 1 ) return v.xzy;
   if ( nSwizzle == 2 ) return v.yxz;
   if ( nSwizzle == 3 ) return v.yzx;
   if ( nSwizzle == 4 ) return v.zxy;
   if ( nSwizzle == 5 ) return v.zyx;
   return v;
}

vec3 rotateXYZ( vec3 v )
{
   float cx = cos( nRotX * DEG ), sx = sin( nRotX * DEG );
   float cy = cos( nRotY * DEG ), sy = sin( nRotY * DEG );
   float cz = cos( nRotZ * DEG ), sz = sin( nRotZ * DEG );
   v = vec3( v.x, cx * v.y - sx * v.z, sx * v.y + cx * v.z );
   v = vec3( cy * v.x + sy * v.z, v.y, -sy * v.x + cy * v.z );
   v = vec3( cz * v.x - sz * v.y, sz * v.x + cz * v.y, v.z );
   return v;
}

// Depth'ten normal: komsu 3B noktalarin capraz carpimi (adim = max(1, smooth) piksel)
vec3 normalFromDepth( vec2 uv )
{
   vec2 px = vec2( max( nSmooth, 1.0 ) ) / vec2( adsk_result_w, adsk_result_h );
   vec2 dx = vec2( px.x, 0.0 ), dy = vec2( 0.0, px.y );
   vec3 ddx = camPos( uv + dx, depthAt( uv + dx ) ) - camPos( uv - dx, depthAt( uv - dx ) );
   vec3 ddy = camPos( uv + dy, depthAt( uv + dy ) ) - camPos( uv - dy, depthAt( uv - dy ) );
   vec3 n = cross( ddx, ddy );
   float len = length( n );
   if ( len < 1e-8 ) return vec3( 0.0, 0.0, 1.0 );
   n /= len;
   return n.z < 0.0 ? -n : n;
}

vec3 getNormal( vec2 uv )
{
   if ( nSource == 1 && depthOn() ) return normalFromDepth( uv );
   vec3 n = applySwizzle( smoothedRaw( uv ) );
   if ( nConvention == 1 ) n.y = -n.y;
   if ( nFlipX ) n.x = -n.x;
   if ( nFlipY ) n.y = -n.y;
   if ( nFlipZ ) n.z = -n.z;
   n = rotateXYZ( n );
   float len = length( n );
   return len > 1e-4 ? n / len : vec3( 0.0, 0.0, 1.0 );
}

// ------------------------------------------------------------------ isiklar
// xyz = isik yonu, w = zayiflama; dist = isige mesafe (golge taramasi icin, yonlu isikta -1)
vec4 lightAt( int mode, vec2 pos, float height, float falloff, float az, float el, vec2 uv, vec3 P, out float dist )
{
   dist = -1.0;
   if ( mode == 1 ) return vec4( dirFromAngles( az, el ), 1.0 );
   vec3 d;
   if ( depthOn() )
   {
      // isik, ikonun altindaki yuzeyden 'height' metre kameraya dogru
      float zl = max( depthAt( pos ) - height, 0.01 );
      d = camPos( pos, zl ) - P;
   }
   else
   {
      float aspect = adsk_result_w / adsk_result_h;
      d = vec3( ( pos - uv ) * vec2( aspect, 1.0 ), height );
   }
   float dist2 = max( dot( d, d ), 1e-8 );
   dist = sqrt( dist2 );
   return vec4( d / dist, 1.0 / ( 1.0 + max( falloff, 0.0 ) * dist2 ) );
}

// Ekran uzayinda isiga dogru depth taramasi: 1 = aydinlik, 0 = golge
float shadowAt( vec3 P, vec3 n, vec3 L, float dist )
{
   if ( !depthOn() || sAmt <= 0.0 ) return 1.0;
   float maxT = dist > 0.0 ? min( dist, sLen ) : sLen;
   vec3 o = P + n * sBias;
   float occ = 0.0;
   for ( int i = 1; i <= SHADOW_STEPS; ++i )
   {
      float t = maxT * pow( float( i ) / float( SHADOW_STEPS ), 1.5 );
      vec3 q = o + L * t;
      if ( q.z > -0.01 ) break;
      vec2 uvq = project( q );
      if ( any( lessThan( uvq, vec2( 0.0 ) ) ) || any( greaterThan( uvq, vec2( 1.0 ) ) ) ) break;
      float dz = -q.z - depthAt( uvq );          // + : yuzey isin onunde
      if ( dz > 0.0 && dz < sThick )
         occ = max( occ, smoothstep( 0.0, 0.05, dz ) * ( 1.0 - 0.5 * t / maxT ) );
   }
   return 1.0 - clamp( sAmt, 0.0, 1.0 ) * occ;
}

float diffuseTerm( vec3 n, vec3 l, float wrap )
{
   return max( ( dot( n, l ) + wrap ) / ( 1.0 + wrap ), 0.0 );
}

float specTerm( vec3 n, vec3 l, float gloss )
{
   vec3 h = normalize( l + vec3( 0.0, 0.0, 1.0 ) );
   float facing = smoothstep( 0.0, 0.05, dot( n, l ) );
   return pow( max( dot( n, h ), 0.0 ), max( gloss, 1.0 ) ) * facing;
}

void main()
{
   vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );

   vec4 src = texture( front, uv );
   float m = texture( matte, uv ).r;
   vec3 n = getNormal( uv );
   float z = depthOn() ? depthAt( uv ) : 0.0;
   vec3 P = camPos( uv, z );

   float kDist, fDist;
   vec4 kLa = lightAt( kMode, kPos, kHeight, kFalloff, kAz, kEl, uv, P, kDist );
   vec4 fLa = lightAt( fMode, fPos, fHeight, fFalloff, fAz, fEl, uv, P, fDist );
   vec3 kL = kLa.xyz, fL = fLa.xyz;
   float kSh = kOn ? shadowAt( P, n, kL, kDist ) : 1.0;
   float fSh = fOn ? shadowAt( P, n, fL, fDist ) : 1.0;
   vec3 kC = kOn ? kCol * kInt * kLa.w * kSh : vec3( 0.0 );
   vec3 fC = fOn ? fCol * fInt * fLa.w * fSh : vec3( 0.0 );

   vec3 diffuse = kC * diffuseTerm( n, kL, kWrap ) + fC * diffuseTerm( n, fL, fWrap ) + aCol * aInt;
   vec3 spec = kC * kSpec * specTerm( n, kL, kGloss ) + fC * fSpec * specTerm( n, fL, fGloss );
   spec += rimCol * rimInt * pow( 1.0 - clamp( n.z, 0.0, 1.0 ), max( rimPower, 0.01 ) );

   vec3 albedo = toLinear( src.rgb );
   vec3 lightPass = albedo * diffuse + spec;

   vec3 lit;
   if ( blendMode == 1 )      lit = lightPass;
   else if ( blendMode == 2 ) lit = 1.0 - ( 1.0 - albedo ) * ( 1.0 - lightPass );
   else                       lit = albedo + lightPass;

   // --- maske ---
   float raw;
   if ( maskMode == 1 )      raw = n.z;
   else if ( maskMode == 2 ) raw = 1.0 - clamp( n.z, 0.0, 1.0 );
   else if ( maskMode == 3 ) raw = diffuseTerm( n, kL, kWrap ) * kLa.w * kSh;
   else if ( maskMode == 4 ) raw = diffuseTerm( n, fL, fWrap ) * fLa.w * fSh;
   else if ( maskMode == 5 ) raw = z;
   else                      raw = dot( n, dirFromAngles( mAz, mEl ) );
   float mask = clamp( ( raw - mLow ) / max( mHigh - mLow, 1e-5 ), 0.0, 1.0 );
   mask = pow( mask, 1.0 / max( mGamma, 0.01 ) );
   if ( mInvert ) mask = 1.0 - mask;
   float alpha = mask * m;

   vec3 outRgb;
   if ( outMode == 1 )      outRgb = lightPass * m;
   else if ( outMode == 2 ) outRgb = diffuse * m;
   else if ( outMode == 3 ) outRgb = spec * m;
   else if ( outMode == 4 ) outRgb = vec3( alpha );
   else if ( outMode == 5 ) outRgb = n * 0.5 + 0.5;
   else if ( outMode == 6 ) outRgb = vec3( z );
   else if ( outMode == 7 ) outRgb = vec3( kSh * fSh );
   else                     outRgb = mix( src.rgb, fromLinear( lit ), clamp( mixAmt, 0.0, 1.0 ) * m );

   fragColor = vec4( outRgb, alpha );
}
