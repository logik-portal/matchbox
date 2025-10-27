//based on https://www.shadertoy.com/view/XscXRl by FabriceNeyret2
// here, operation 1

uniform sampler2D adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 iResolution = vec2(adsk_result_w, adsk_result_h);
uniform float amount; // 8.
uniform int erosion_dilation;
uniform float look;
uniform int B;

#define p .3

bool brush(vec2 d)                  //  brush element  =
{ d = abs(d);
  return  B==0 ? dot(d,d) <= amount*amount                    // disk
        : B==1 ? pow(d.x,p)+pow(d.y,p) <= pow(amount,p)  // star(p)
        : B==2 ? d.x+d.y < amount                        // diamond
        : B==3 ? max(d.x,d.x*.5+d.y*.87) < amount        // hexagon
               : true;                              // square
// todo: distance-weighted brush
}


void main()
{
  	vec2 R = iResolution.xy, d;
    vec2 U = gl_FragCoord.xy;
    vec4 O = vec4(0.0);
    vec2 uv = gl_FragCoord.xy / iResolution;
    vec4 f = texture2D(adsk_results_pass1, uv);
    vec4 m=vec4(1e9), M=-m;
	  for (float y = -amount; y<=amount; y++)
	  for (float x = -amount; x<=amount; x++)
          if (brush(d=vec2(x,y)))
          {
              vec4 t = texture2D(adsk_results_pass1,(U+d)/R);
              m = min(m,t);
              M = max(M,t);
          }

          if ( erosion_dilation == 2 )
          O = M;
          else
          O = m;
          O = mix(O, f, look);
    gl_FragColor = O;
}
