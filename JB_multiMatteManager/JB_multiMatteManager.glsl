//uniform float redChan;
//uniform float greenChan;
//uniform float blueChan;

uniform bool redChannel1;
uniform bool greenChannel1;
uniform bool blueChannel1;
// declare the variables (switches for the channels for each input)

uniform bool redChannel2;
uniform bool greenChannel2;
uniform bool blueChannel2;

uniform bool redChannel3;
uniform bool greenChannel3;
uniform bool blueChannel3;

uniform bool invertAlpha;

// canvas size

uniform float adsk_result_w;
uniform float adsk_result_h;

// number or inputs

uniform sampler2D input1;
uniform sampler2D input2;
uniform sampler2D input3;

void main(void)
{
	vec2 st;
	// normalize x and y coordinate
		
	st.x = gl_FragCoord.x / adsk_result_w;
	st.y = gl_FragCoord.y / adsk_result_h;

	// get pixel informations RGB for each input
	
	vec4 getColorInput1;
	getColorInput1 = texture2D(input1, st);
	
	vec4 getColorInput2;
	getColorInput2 = texture2D(input2, st);

	vec4 getColorInput3;
	getColorInput3 = texture2D(input3, st);

	
	// multiply rgb by the switch (0/1 active or not)
	
	getColorInput1.r *= float(redChannel1);
	getColorInput1.g *= float(greenChannel1);
	getColorInput1.b *= float(blueChannel1);
	
	getColorInput2.r *= float(redChannel2);
	getColorInput2.g *= float(greenChannel2);
	getColorInput2.b *= float(blueChannel2);

	getColorInput3.r *= float(redChannel3);
	getColorInput3.g *= float(greenChannel3);
	getColorInput3.b *= float(blueChannel3);


	// compute the resulting pixel's rgba
	 
	vec4 result;
	
	result.r = getColorInput1.r + getColorInput2.r + getColorInput3.r;
	result.g = getColorInput1.g + getColorInput2.g + getColorInput3.g;
	result.b = getColorInput1.b + getColorInput2.b + getColorInput3.b;

	
	result.a = result.r +result.b +result.g;
	if (invertAlpha) {result.a = 1-result.a;}

	//process the output
	gl_FragColor = result;
}
