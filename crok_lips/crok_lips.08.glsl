#version 120
// load softened lip mask

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass7;
uniform float m_amount;

float adsk_getLuminance(vec3 rgb);

float alpha(vec2 uv)
{
   return adsk_getLuminance(texture2D(adsk_results_pass7, uv).rgb);
}

void main(void)
{
  vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
  vec2 size_inv=vec2(1.0/adsk_result_w,1.0/adsk_result_h);

	float p_m_amount = -1.0 * m_amount;
  float cr=cos(0.0);
  float sr=sin(0.0);

	mat3 g_trans = mat3( cr*p_m_amount*size_inv.x, sr*p_m_amount*size_inv.y, 0.0, -sr*p_m_amount*size_inv.x, cr*p_m_amount*size_inv.y, 0.0, 0.0, 0.0, 1.0 );

	vec4 disp_h = vec4(alpha(uv.xy+vec2(0.0,size_inv.y)),alpha(uv.xy+vec2(0.0,-size_inv.y)),alpha(uv.xy+vec2(-size_inv.x,0.0)),alpha(uv.xy+vec2(size_inv.x,0.0)));
	vec4 disp_d = vec4(alpha(uv.xy+size_inv),alpha(uv.xy-size_inv),alpha(uv.xy+vec2(-size_inv.x,size_inv.y)),alpha(uv.xy+vec2(size_inv.x,-size_inv.y)));

	disp_h = max( disp_h, 0.0);
	disp_d = max( disp_d, 0.0);

	vec4 levels = vec4(1.0);
	disp_h = pow( disp_h, levels );
	disp_d = pow(disp_d, levels );

	vec2 gradient = vec2(0.0);
	gradient.x = dot( disp_h, vec4(0.0, 0.0, 2.0, -2.0)) + dot( disp_d, vec4(-1.0, 1.0, 1.0, -1.0));
	gradient.y = dot( disp_h, vec4(-2.0, 2.0, 0.0, 0.0)) + dot( disp_d, vec4(-1.0, 1.0, -1.0, 1.0));

	gradient = ( g_trans * vec3( gradient, 1.0)).xy;

	vec4 col = vec4(texture2D(adsk_results_pass7, uv.xy+gradient ).rgb, 1.0);

  gl_FragColor = vec4(col);

}
