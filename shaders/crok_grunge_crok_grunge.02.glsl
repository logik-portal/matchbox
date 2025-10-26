#version 120
// blur Matte Vertical
uniform float blur_m, adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1, strength;

void main()
{
   vec2 coords = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
   float s = texture2D(strength, coords).r;
   float am = blur_m * s;
   int f0int = int(am);
   vec4 accu = vec4(0.0);
   float energy = 0.0;
   vec4 blur_bgy = vec4(0.0);

   for( int y = -f0int; y <= f0int; y++)
   {
      vec2 currentCoord = vec2(coords.x, coords.y+float(y)/adsk_result_h);
      vec4 aSample = texture2D(adsk_results_pass1, currentCoord).rgba;
      float anEnergy = 1.0 - ( abs(float(y)) / blur_m);
      energy += anEnergy;
      accu+= aSample * anEnergy;
  }

   blur_bgy =
      energy > 0.0 ? (accu / energy) :
                     texture2D(adsk_results_pass1, coords).rgba;

   gl_FragColor = vec4( blur_bgy );
}
