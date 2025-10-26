#version 120
// based on https://www.shadertoy.com/view/XsBfRG

uniform sampler2D adsk_results_pass1, adsk_results_pass2, adsk_results_pass3;
uniform float adsk_result_w, adsk_result_h;
uniform bool DIR;
uniform int view ;

vec2 iResolution = vec2(adsk_result_w, adsk_result_h);

float fromRgb( vec3 v ) {
    return (( v.z * 256.0 + v.y) * 256.0 + v.x) * 255.0;
}

vec4 draw( vec2 uv ) {
  float st = texture2D( adsk_results_pass2, uv ).r;
    vec2 dir = DIR ? vec2( 0.0, 1.0 ) : vec2( 1.0, 0.0 );
    float wid = DIR ? iResolution.y : iResolution.x;
    float pos = DIR ? floor( uv.y * iResolution.y ) : floor( uv.x * iResolution.x );

    for ( int i = 0; i < int( wid ); i ++ ) {
        vec2 p = uv + dir * float( i ) / wid;
        if ( p.x < 1.0 && p.y < 1.0 ) {
            float v = fromRgb( texture2D( adsk_results_pass3, p ).xyz );
            if ( abs( v - pos ) < 0.5 ) {
                return texture2D( adsk_results_pass1, p ) ;
                break;
            }
        }

        p = uv - dir * float( i ) / wid;
        if ( 0.0 < p.x && 0.0 < p.y ) {
            float v = fromRgb( texture2D( adsk_results_pass3, p ).xyz ) ;
            if ( abs( v - pos ) < 0.5 ) {
                return texture2D( adsk_results_pass1, p );
                break;
            }
        }
    }

    return vec4( 1.0, 0.0, 1.0, 1.0 );
}

void main()
{
  vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
  vec4 org = texture2D( adsk_results_pass1, uv );
  vec4 col = draw( uv );
  col.rgb = vec3(org.a * col.rgb + (1.0 - org.a) * org.rgb);
   gl_FragColor = vec4(col.rgb, org.a);
    
}
