uniform sampler2D adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h, adsk_time ;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);
float time = adsk_time *.05;

vec3 dof(sampler2D buffer, vec2 uv, float distanceOfFocus){
	vec3 finalColor;
    const float squareEdge = 3.0;
    const float iters = (squareEdge*2.0+1.0)*(squareEdge*2.0+1.0);
    float l = abs(distanceOfFocus-texture2D(buffer,uv).a);
    float radiousOfDepth = 1.0;
    float dofLevel = clamp((l-radiousOfDepth )*0.1,0.0,1.0);
    for( float i = -squareEdge; i <= squareEdge; i++)
        for( float j = -squareEdge; j <= squareEdge; j++)
            finalColor += texture2D(buffer,uv+vec2(i,j)*0.0075*dofLevel).xyz;

    finalColor /= iters;

    //return vec3(dofLevel);
    return finalColor;
}

void main()
{
	vec2 uv =gl_FragCoord.xy/resolution.xy;

	gl_FragColor = vec4(dof(adsk_results_pass1,uv,14.8),1.0);
}
