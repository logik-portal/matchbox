#version 120

// based on Timothy Lottes "FXAA"
// aa front

uniform sampler2D adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h;
uniform float aa_mix;

float adsk_getLuminance( in vec3 color );

void main()
{
   vec2 pix = vec2(1.0) / vec2( adsk_result_w, adsk_result_h );
   vec2 uv = gl_FragCoord.xy * pix;
   vec4 o = texture2D( adsk_results_pass1, uv);

   float l  = adsk_getLuminance( texture2D( adsk_results_pass1, uv ).rgb);
   float nw = adsk_getLuminance( texture2D( adsk_results_pass1, uv + pix * vec2(-1.0, -1.0) ).rgb);
   float ne = adsk_getLuminance( texture2D( adsk_results_pass1, uv + pix * vec2(1.0, -1.0) ).rgb);
   float sw = adsk_getLuminance( texture2D( adsk_results_pass1, uv + pix * vec2(-1.0, 1.0) ).rgb);
   float se = adsk_getLuminance( texture2D( adsk_results_pass1, uv + pix * vec2(1.0, 1.0) ).rgb);

   vec2 lb = vec2( min( l, min( min( nw, ne ), min( sw, se ))), max( l, max( max( nw, ne) , max( sw, se ))));
   vec2 g = vec2(((sw + se) - (nw + ne)), ((nw + sw) - (ne + se)));

   float gr = max(( nw + ne + sw + se ) * 0.03125, 0.0078125 );
   float gz = 1.0 / ( min(abs(g.x), abs(g.y))+ gr );
   g = min( vec2(8.0), max( vec2(-8.0), g*gz)) * pix;
   vec4 col_a = 0.5 * ( texture2D(adsk_results_pass1,  uv + g * -0.16666666666667) + texture2D(adsk_results_pass1,  uv + g * 0.16666666666667));
   vec4 col_b = col_a * 0.5 + 0.25 * ( texture2D(adsk_results_pass1,  uv + g * -0.5) + texture2D(adsk_results_pass1,  uv + g * 0.5));
   float l_b = adsk_getLuminance( col_b.rgb );

   vec4 c = (( l_b < lb.x ) || ( l_b > lb.y )) ? col_a : col_b;
   c = mix(o, c, aa_mix);
   gl_FragColor = c;
}
