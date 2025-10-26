//	License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//	
//	started trying random things without a goal in mind and ended up here.
//	there's probably lots of redundant and senseless code. yes, I am ashamed of myself.
//	
//	raymarching and lighting code courtesy of iq.
//	
//	~bj.2013

uniform sampler2D inputVideo;
uniform float adsk_time;
uniform float adsk_result_w, adsk_result_h;

uniform vec2 paramPos;

uniform float paramSpeed;
uniform float paramWaveSize;

const float PI	= 3.14159;


void main(void)
{
    vec2 iResolution = vec2(adsk_result_w, adsk_result_h);
	vec2 rcpResolution = 1.0 / iResolution.xy;
	vec2 uv = gl_FragCoord.xy * rcpResolution;
	
	// = vec2 ndc    = -1.0 + uv * 2.0;
	// = vec2 mouse  = -1.0 + 2.0 * iMouse.xy * rcpResolution;
	vec4 mouseNDC = -1.0 + vec4(paramPos.xy, uv) * 2.0;
	vec2 diff     = mouseNDC.zw - mouseNDC.xy;
	
	float dist  = length(diff);       // = sqrt(diff.x * diff.x + diff.y * diff.y);
	float angle = PI * dist * paramWaveSize + adsk_time * paramSpeed /100.0;
    
	vec3 sincos;
	sincos.x = sin(angle);
	sincos.y = cos(angle);
	sincos.z = -sincos.x;
	
	vec2 newUV;
	mouseNDC.zw -= mouseNDC.xy;
	newUV.x = dot(mouseNDC.zw, sincos.yz);	// = ndc.x * cos(angle) - ndc.y * sin(angle);
	newUV.y = dot(mouseNDC.zw, sincos.xy);  // = ndc.x * sin(angle) + ndc.y * cos(angle);
	
	vec3 col = texture2D( inputVideo, newUV.xy ).xyz;
	
	gl_FragColor = vec4(col, 1);
}