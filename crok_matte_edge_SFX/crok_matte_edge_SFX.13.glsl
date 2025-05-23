#version 120
// overall blur
uniform float blur_matte_all, oblur_aspect, adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass12, strength;

void main()
{
   vec2 coords = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
   float s = texture2D(strength, coords).r;
   float b_aspect = oblur_aspect;
   if ( oblur_aspect > 1.0 )
    b_aspect = (b_aspect - 1.0) * 10.0 + 1.0;
   float blur = b_aspect * blur_matte_all * s;
   int f0int = int(blur);
   float accu = 0.0;
   float energy = 0.0;
   float blur_fg_x = 0.0;

   for( int x = -f0int; x <= f0int; x++)
   {
      vec2 currentCoord = vec2(coords.x+float(x)/adsk_result_w, coords.y);
      float aSample = texture2D(adsk_results_pass12, currentCoord).a;
      float anEnergy = 1.0 - ( abs(float(x)) / blur);
      energy += anEnergy;
      accu+= aSample * anEnergy;
   }

   blur_fg_x =
      energy > 0.0 ? (accu / energy) :
                     texture2D(adsk_results_pass12, coords).a;

   gl_FragColor = vec4( blur_fg_x );
}
