vec3 adsk_getDiffuseMapCoord();
vec4 adsk_getDiffuseMapValue(in vec2 texCoord);
uniform float adskUID_amount;

float adskUID_alpha(vec2 uv)
{
   return adsk_getDiffuseMapValue(uv.xy).a;
}


vec4 adskUID_lightbox(vec4 source)
{
	vec3 uv = adsk_getDiffuseMapCoord();
	vec2 size_inv=vec2(1.0 / 2000.0, 1.0 / 2000.0);
	
	float p_amount = -1.0 * adskUID_amount;
    float cr=cos(0.0);
    float sr=sin(0.0);
	
	mat3 g_trans = mat3( cr*p_amount*size_inv.x, sr*p_amount*size_inv.y, 0.0, -sr*p_amount*size_inv.x, cr*p_amount*size_inv.y, 0.0, 0.0, 0.0, 1.0 );

	vec4 disp_h = vec4(adskUID_alpha(uv.xy+vec2(0.0,size_inv.y)),adskUID_alpha(uv.xy+vec2(0.0,-size_inv.y)),adskUID_alpha(uv.xy+vec2(-size_inv.x,0.0)),adskUID_alpha(uv.xy+vec2(size_inv.x,0.0)));
	vec4 disp_d = vec4(adskUID_alpha(uv.xy+size_inv),adskUID_alpha(uv.xy-size_inv),adskUID_alpha(uv.xy+vec2(-size_inv.x,size_inv.y)),adskUID_alpha(uv.xy+vec2(size_inv.x,-size_inv.y)));
		
	disp_h = max( disp_h, 0.0);
	disp_d = max( disp_d, 0.0);
		
	vec4 levels = vec4(1.0);
	disp_h = pow( disp_h, levels );
	disp_d = pow(disp_d, levels );
	
	vec2 gradient = vec2(0.0);
	gradient.x = dot( disp_h, vec4(0.0, 0.0, 2.0, -2.0)) + dot( disp_d, vec4(-1.0, 1.0, 1.0, -1.0));
	gradient.y = dot( disp_h, vec4(-2.0, 2.0, 0.0, 0.0)) + dot( disp_d, vec4(-1.0, 1.0, -1.0, 1.0));
		
	gradient = ( g_trans * vec3( gradient, 1.0)).xy;
		
	vec4 col = vec4(adsk_getDiffuseMapValue(uv.xy+gradient ).rgb, 1.0);
	
	return vec4(col.rgb, source.a);
}
