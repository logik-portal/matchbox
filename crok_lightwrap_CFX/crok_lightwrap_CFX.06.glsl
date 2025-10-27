#version 120
// blur BG for auto cc
uniform float blur_bg_4_auto_cc, adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass5;

void main()
{
   vec2 coords = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
   int f0int = int(blur_bg_4_auto_cc);
   vec4 accu = vec4(0);
   float energy = 0.0;
   vec4 blur_bgx = vec4(0.0);

   for( int x = -f0int; x <= f0int; x++)
   {
      vec2 currentCoord = vec2(coords.x+float(x)/adsk_result_w, coords.y);
      vec4 aSample = texture2D(adsk_results_pass5, currentCoord).rgba;
      float anEnergy = 1.0 - ( abs(float(x)) / blur_bg_4_auto_cc);
      energy += anEnergy;
      accu+= aSample * anEnergy;
   }

   blur_bgx =
      energy > 0.0 ? (accu / energy) :
                     texture2D(adsk_results_pass5, coords).rgba;

   gl_FragColor = vec4( blur_bgx );
}
