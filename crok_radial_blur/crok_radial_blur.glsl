// RadialBlur - Shader
 
uniform sampler2D Texture;   // scene texture
uniform float adsk_result_w, adsk_result_h;

uniform vec2 radial_size;    // texel size
 
uniform float radial_blur;   // blur factor
uniform float radial_bright; // bright factor
 
uniform vec2 radial_origin;  // blur origin
uniform int pBlursteps; 

float steps = float(pBlursteps);

void main(void)
{
  vec2 TexCoord = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
 
  vec4 SumColor = vec4(0.0, 0.0, 0.0, 0.0);
  TexCoord += radial_size * 0.5 - radial_origin;
 
  for (int i = 0; i < pBlursteps; i++) 
  {
    float scale = 1.0 - radial_blur * (float(i) / steps);
    SumColor += texture2D(Texture, TexCoord * scale + radial_origin);
  }
 
  gl_FragColor = SumColor / steps * radial_bright;
}