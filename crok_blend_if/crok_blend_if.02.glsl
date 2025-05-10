#version 120

uniform sampler2D back, adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h;
uniform float this_layer_low, this_layer_high, this_layer_threshold_low, this_layer_threshold_high;
float adsk_getLuminance( in vec3 color );

void main()
{
   vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
   vec4 c = texture2D(adsk_results_pass1, uv);
   vec4 bg = texture2D(back, uv);
   float l  = adsk_getLuminance( texture2D( adsk_results_pass1, uv ).rgb);

   // START this layer low slider
   float this_low = this_layer_low - this_layer_threshold_low * 0.5;
   float l1 = min(max(l - this_low, 0.0) / (this_layer_low - this_low), 1.0);
   // END this layer low slider

   // START this layer high slider
   float this_high = this_layer_high - this_layer_threshold_high * 0.5;
   float l2= min(max(l - this_high, 0.0) / (this_layer_high - this_high), 1.0);
   l2 = 1.0 - l2;
   // END this layer high slider

   // combining the mattes
   float l3 = l1 * l2;
   l3 = l3 * c.a;
   c.rgb = vec3(l3 * c.rgb + (1.0 - l3) * bg.rgb);

   gl_FragColor = vec4(c.rgb, l3);
}
