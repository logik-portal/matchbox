#version 120
// blur Matte Horizontal
uniform float blur_m, adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass2, strength;

void main()
{
   vec2 coords = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
   float s = texture2D(strength, coords).r;
   float am = blur_m * s;
   int f0int = int(am);
   vec4 accu = vec4(0.0);
   float energy = 0.0;
   vec4 blur_bgx = vec4(0.0);

   for( int x = -f0int; x <= f0int; x++)
   {
      vec2 currentCoord = vec2(coords.x+float(x)/adsk_result_w, coords.y);
      vec4 aSample = texture2D(adsk_results_pass2, currentCoord).rgba;
      float anEnergy = 1.0 - ( abs(float(x)) / blur_m);
      energy += anEnergy;
      accu+= aSample * anEnergy;
   }

   blur_bgx =
      energy > 0.0 ? (accu / energy) :
                     texture2D(adsk_results_pass2, coords).rgba;

   gl_FragColor = vec4( blur_bgx );
}
