#version 120
// based on https://www.shadertoy.com/view/XsBfRG

uniform sampler2D front, matte;
uniform float adsk_result_w, adsk_result_h;
uniform float angle;
uniform bool enable_rotation;

void main()
{
  vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
  vec2 uv_without_rot = uv;
  vec3 c = vec3(0.0);
  float m = 0.0;

  if ( enable_rotation)
  {
    float rotation = angle/180.*3.14159265;
    float size = .5;
    vec2 frontCoords = uv ;
    float ratio = adsk_result_w/adsk_result_h ;
    // rotate and scale
    vec2 ctr = vec2(0.5);
    mat2 rotMat = mat2( cos(-rotation)*ratio, -sin(-rotation),
                       sin(-rotation)*ratio, cos(-rotation) );
    frontCoords -= ctr;
    frontCoords *= rotMat/size;
    frontCoords /= vec2(ratio,1.);
    frontCoords += ctr;
    c = texture2D(front, frontCoords).rgb;
    m = texture2D(matte, frontCoords).r;
  }

  else
  {
    c = texture2D(front, uv_without_rot).rgb;
    m = texture2D(matte, uv_without_rot).r;
  }


    gl_FragColor = vec4(c, m);
}
