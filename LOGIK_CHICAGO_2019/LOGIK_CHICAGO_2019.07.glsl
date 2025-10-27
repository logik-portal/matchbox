#version 120
// grain 2/4

uniform sampler2D adsk_results_pass6;
uniform float adsk_result_w, adsk_result_h;

float blur = 1.0;
void main()
{
   vec2 coords = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
   float p_blur = 1.0;
 	 float softness = (blur + 1.) * p_blur;
   int f0int = int(softness);
   vec4 accu = vec4(0.0);
   float energy = 0.0;
   vec4 finalColor = vec4(0.0);

   for( int x = -f0int; x <= f0int; x++)
   {
      vec2 currentCoord = vec2(coords.x+float(x)/adsk_result_w, coords.y);
      vec4 aSample = texture2D(adsk_results_pass6, currentCoord).rgba;
      float anEnergy = 1.0 - ( abs(float(x)) / softness);
      energy += anEnergy;
      accu += aSample * anEnergy;
   }

   finalColor =
	   energy > 0.0 ? (accu / energy) :
                    texture2D(adsk_results_pass6, coords).rgba;


   gl_FragColor = vec4( finalColor );
}
