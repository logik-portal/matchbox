#version 120
// based on https://www.shadertoy.com/view/XsBfRG

uniform sampler2D adsk_results_pass1, adsk_results_pass2, adsk_results_pass3, adsk_results_pass4;
uniform float adsk_result_w, adsk_result_h;
uniform float angle;
uniform int view;
uniform bool enable_rotation;

void main()
{
  vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
  float rotation = angle/180.*3.14159265;
  float size = 1.0;
  vec3 c = texture2D(adsk_results_pass4, uv).rgb;
  float m = texture2D(adsk_results_pass4, uv).a;

  if ( enable_rotation)
  {
    size = 2.;
    vec2 frontCoords = uv ;
    float ratio = adsk_result_w/adsk_result_h ;
    // rotate and scale
    vec2 ctr = vec2(0.5);
    mat2 rotMat = mat2( cos(rotation)*ratio, -sin(rotation),
                       sin(rotation)*ratio, cos(rotation) );
    frontCoords -= ctr;
    frontCoords *= rotMat/size;
    frontCoords /= vec2(ratio,1.);
    frontCoords += ctr;
    c = texture2D(adsk_results_pass4, frontCoords).rgb;
    m = texture2D(adsk_results_pass4, frontCoords).a;
  }

    gl_FragColor = vec4(c, m);
}
