uniform float adsk_result_w;
uniform float adsk_result_h;

uniform float scanlineX;
uniform float scanlineY;

uniform float offsetX;
uniform float offsetY;

uniform float blender;

//uniform bool rx;
//uniform bool ry;
//uniform bool rxi;
//uniform bool ryi;

//uniform bool gx;
//uniform bool gy;
//uniform bool gxi;
//uniform bool gyi;

//uniform bool bx;
//uniform bool by;
//uniform bool bxi;
//uniform bool byi;
uniform float rx;
uniform float ry;
uniform float gx;
uniform float gy;
uniform float bx;
uniform float by;


uniform bool useMattebool;

// number or inputs

uniform sampler2D input1;
uniform sampler2D input2;
uniform sampler2D input3;

void main(void)
{
	vec2 stDisp;
	stDisp.x = gl_FragCoord.x / adsk_result_w;
	stDisp.y = gl_FragCoord.y / adsk_result_h;
	
	vec4 getDispInput1;
	getDispInput1 = texture2D(input2, stDisp);

	
	vec2 st2;
	
	st2.x =( gl_FragCoord.x - (((rx)*getDispInput1.x + (bx) * getDispInput1.z + (gx) * getDispInput1.y)*scanlineX)+ offsetX) / adsk_result_w;
//	st2.x =( gl_FragCoord.x - (((rx -rxi)*getDispInput1.x + (bx - bxi) * getDispInput1.z + (gx - gxi) * getDispInput1.y)*scanlineX)+ offsetX) / adsk_result_w;
	st2.y =( gl_FragCoord.y - (((ry)*getDispInput1.x + (by) * getDispInput1.z + (gy) * getDispInput1.y)*scanlineY)+ offsetY) / adsk_result_h;

//	st2.y =( gl_FragCoord.y - (((ry -ryi)*getDispInput1.x + (by - byi) * getDispInput1.z + (gy - gyi) * getDispInput1.y)*scanlineY)+ offsetY) / adsk_result_h;


	vec4 getColorInputDisp;
	getColorInputDisp = texture2D(input1, st2);
	
	vec4 getColorInputDispMap;
	getColorInputDispMap = texture2D(input3, st2);


	vec2 st;

	// get pixel informations RGB for each input
	
	st.x = gl_FragCoord.x  / adsk_result_w;
	st.y = gl_FragCoord.y / adsk_result_h;

	
	vec4 getColorInputClean;
	getColorInputClean = texture2D(input1, st);
	
	vec4 outColor;

	outColor = (((getColorInputDisp*(1+(useMattebool*(getColorInputDispMap-1)))) + (getColorInputClean*(useMattebool*(1-getColorInputDispMap))))*(1-blender))+ (getColorInputClean*blender);
		
	outColor.a = getColorInputDispMap.r;
	
		//process the output
	gl_FragColor = outColor;
}
