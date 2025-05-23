/*by musk License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

 Trying to get some interesting looking lens flares.

 13/08/13: 
	published

muuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuusk!*/

uniform sampler2D inputNoise;
uniform float adsk_inputNoise_w, adsk_inputNoise_h;
uniform float adsk_time;
uniform float adsk_result_w, adsk_result_h;

uniform vec2 paramDirection;
uniform bool paramMove;
uniform float paramSpeed;

float noise(float t)
{
	return texture2D(inputNoise,vec2(t,.0)/vec2(adsk_inputNoise_w, adsk_inputNoise_h).xy).x;
}
float noise(vec2 t)
{
	return texture2D(inputNoise,t/vec2(adsk_inputNoise_w, adsk_inputNoise_h).xy).x;
}

vec3 lensflare(vec2 uv,vec2 pos)
{
	vec2 main = uv-pos;
	vec2 uvd = uv*(length(uv));
	
	float ang = atan(main.x,main.y);
	float dist=length(main); dist = pow(dist,.1);
	float n = noise(vec2(ang*16.0,dist*32.0));
	
	float f0 = 1.0/(length(uv-pos)*16.0+1.0);
	
	f0 = f0+f0*(sin(noise((pos.x+pos.y)*2.2+ang*4.0+5.954)*16.0)*.1+dist*.1+.8);
	
	float f1 = max(0.01-pow(length(uv+1.2*pos),1.9),.0)*7.0;

	float f2 = max(1.0/(1.0+32.0*pow(length(uvd+0.8*pos),2.0)),.0)*00.25;
	float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.85*pos),2.0)),.0)*00.23;
	float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.9*pos),2.0)),.0)*00.21;
	
	vec2 uvx = mix(uv,uvd,-0.5);
	
	float f4 = max(0.01-pow(length(uvx+0.4*pos),2.4),.0)*6.0;
	float f42 = max(0.01-pow(length(uvx+0.45*pos),2.4),.0)*5.0;
	float f43 = max(0.01-pow(length(uvx+0.5*pos),2.4),.0)*3.0;
	
	uvx = mix(uv,uvd,-.4);
	
	float f5 = max(0.01-pow(length(uvx+0.2*pos),5.5),.0)*2.0;
	float f52 = max(0.01-pow(length(uvx+0.4*pos),5.5),.0)*2.0;
	float f53 = max(0.01-pow(length(uvx+0.6*pos),5.5),.0)*2.0;
	
	uvx = mix(uv,uvd,-0.5);
	
	float f6 = max(0.01-pow(length(uvx-0.3*pos),1.6),.0)*6.0;
	float f62 = max(0.01-pow(length(uvx-0.325*pos),1.6),.0)*3.0;
	float f63 = max(0.01-pow(length(uvx-0.35*pos),1.6),.0)*5.0;
	
	vec3 c = vec3(.0);
	
	c.r+=f2+f4+f5+f6; c.g+=f22+f42+f52+f62; c.b+=f23+f43+f53+f63;
	c = c*1.3 - vec3(length(uvd)*.05);
	c+=vec3(f0);
	
	return c;
}

vec3 cc(vec3 color, float factor,float factor2) // color modifier
{
	float w = color.x+color.y+color.z;
	return mix(color,vec3(w)*factor,w*factor2);
}

void main(void)
{
    vec2 iResolution = vec2(adsk_result_w, adsk_result_h);
	vec2 uv = gl_FragCoord.xy / iResolution.xy - 0.5;
	uv.x *= iResolution.x/iResolution.y; //fix aspect ratio
	vec3 mouse = vec3(paramDirection.xy - 0.5,0.1);
	mouse.x *= iResolution.x/iResolution.y; //fix aspect ratio
	if (paramMove)
	{
		mouse.x=sin(adsk_time * paramSpeed / 100.0 )*.5;
		mouse.y=sin(adsk_time* paramSpeed / 100.0 *.913)*.5;
	}
	
	vec3 color = vec3(1.4,1.2,1.0)*lensflare(uv,mouse.xy);
	color -= noise(gl_FragCoord.xy)*.015;
	color = cc(color,.5,.1);
	gl_FragColor = vec4(color,1.0);
}

