uniform float adsk_result_w;
uniform float adsk_result_h;
uniform sampler2D adsk_previous_frame_input1;
uniform sampler2D adsk_next_frame_input1;
uniform sampler2D input2;
uniform sampler2D input1;

uniform float redTS;
uniform float greenTS;
uniform float blueTS;

uniform int iterations;
uniform bool interpolate;

void main(void)
{
	vec2 st0;
	st0.x = gl_FragCoord.x / adsk_result_w;
	st0.y = gl_FragCoord.y / adsk_result_h;
	
	vec4 getColPixel0;
	getColPixel0 = texture2D(input1, st0);
	
	vec3 color;
	vec2 st1;
	vec2 st2;
	vec2 st3;
	vec4 getColPixel1;		
		
   	vec3 prev = texture2D( adsk_previous_frame_input1, st0 ).rgb;
  	vec3 next = texture2D( adsk_next_frame_input1, st0 ).rgb;
   	vec3 curr = texture2D( input1, st0 ).rgb;
		
		
		
	color = getColPixel0.rgb;
	float colorBuffer;
	int count=0;
	for (int x = 0; x <=iterations; x++)
	{
		for (int y = 1; y<= iterations; y++)
		{
			st1.x = (gl_FragCoord.x+x) / adsk_result_w;
			st1.y = (gl_FragCoord.y+y) / adsk_result_h;
			if ( (gl_FragCoord.x+x) >=0 && (gl_FragCoord.x+x) <= adsk_result_w){getColPixel1 = texture2D(input2, st1);}
			if ( (gl_FragCoord.y+y) >=0 && (gl_FragCoord.y+y) <= adsk_result_h){getColPixel1 = texture2D(input2, st1);}		
			color += getColPixel1.rgb;
			count++;
		}
		count++;
	}
	
	for (int x = 0; x <=iterations; x++)
	{
		for (int y = 1; y<= iterations; y++)
		{
			st1.x = (gl_FragCoord.x-x) / adsk_result_w;
			st1.y = (gl_FragCoord.y+y) / adsk_result_h;
			if ( (gl_FragCoord.x-x) >=0 && (gl_FragCoord.x-x) <= adsk_result_w){getColPixel1 = texture2D(input2, st1);}
			if ( (gl_FragCoord.y+y) >=0 && (gl_FragCoord.y+y) <= adsk_result_h){getColPixel1 = texture2D(input2, st1);}		
			color += getColPixel1.rgb;
			count++;
		}
		count++;
	}
	
	for (int x = 0; x <=iterations; x++)
	{
		for (int y = 1; y<= iterations; y++)
		{
			st1.x = (gl_FragCoord.x+x) / adsk_result_w;
			st1.y = (gl_FragCoord.y-y) / adsk_result_h;
			if ( (gl_FragCoord.x+x) >=0 && (gl_FragCoord.x+x) <= adsk_result_w){getColPixel1 = texture2D(input2, st1);}
			if ( (gl_FragCoord.y-y) >=0 && (gl_FragCoord.y-y) <= adsk_result_h){getColPixel1 = texture2D(input2, st1);}		
			color += getColPixel1.rgb;
			count++;
		}
		count++;
	}

	for (int x = 0; x <=iterations; x++)
	{
		for (int y = 1; y<= iterations; y++)
		{
			st1.x = (gl_FragCoord.x-x) / adsk_result_w;
			st1.y = (gl_FragCoord.y-y) / adsk_result_h;
			if ( (gl_FragCoord.x-x) >=0 && (gl_FragCoord.x-x) <= adsk_result_w){getColPixel1 = texture2D(input2, st1);}
			if ( (gl_FragCoord.y-y) >=0 && (gl_FragCoord.y-y) <= adsk_result_h){getColPixel1 = texture2D(input2, st1);}		
			color += getColPixel1.rgb;
			count++;
		}
		count++;
	}

	color /= count;
	float buffer = 1;
	vec3 outcolor = curr;

	if ((color.r*redTS)>=(color.b*blueTS) && (color.r*redTS)>=(color.g*greenTS) ) {
		outcolor = next;
		if (interpolate == true) {outcolor = (next+curr)*0.5;}
	}
	if ((color.g*greenTS)>=(color.r*redTS) && (color.g*greenTS)>=(color.b*blueTS) ) {
		outcolor = curr;
	}
	if ((color.b*blueTS)>=(color.r*redTS) && (color.b*blueTS)>=(color.g*greenTS) ) {
		outcolor = prev;
		if (interpolate == true) {outcolor = (next+prev)*0.5;}
	}

	vec4 outColor;
	gl_FragColor =  vec4(outcolor,1.0);
}
