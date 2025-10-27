#version 120

uniform float blur, adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1;

void main()
{
   vec2 coords = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
   int f0int = int(blur);
   vec3 accu = vec3(0.0);
   float energy = 0.0;
   vec3 blur_fg_y = vec3(0.0);

   for( int y = -f0int; y <= f0int; y++)
   {
      vec2 currentCoord = vec2(coords.x, coords.y+float(y)/adsk_result_h);
      vec3 aSample = texture2D(adsk_results_pass1, currentCoord).rgb;
      float anEnergy = 1.0 - ( abs(float(y)) / blur);
      energy += anEnergy;
      accu+= aSample * anEnergy;
   }

   blur_fg_y =
      energy > 0.0 ? (accu / energy) :
                     texture2D(adsk_results_pass1, coords).rgb;

   gl_FragColor.rgb = blur_fg_y;
}
