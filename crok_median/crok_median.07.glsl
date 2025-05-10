#version 120
// based on https://www.shadertoy.com/view/MtcSzH by ttoinou
uniform sampler2D adsk_results_pass2, adsk_results_pass3, adsk_results_pass4, adsk_results_pass5, adsk_results_pass6;

uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform int num_iter;

void main()
{
	vec2 uv = gl_FragCoord.xy / res;
  vec4 col = vec4(0.0);

	if (num_iter == 1){
	col = texture2D(adsk_results_pass2,uv);
	}
	else if (num_iter == 2){
	col = texture2D(adsk_results_pass3,uv);
	}
	else if (num_iter == 3){
	col = texture2D(adsk_results_pass4,uv);
	}
	else if (num_iter == 4){
	col = texture2D(adsk_results_pass5,uv);
	}
	else if (num_iter == 5){
	col = texture2D(adsk_results_pass6,uv);
	}

	gl_FragColor = vec4(col.rgb, 1.0);
}
