uniform float adsk_result_w;
uniform float adsk_result_h;

uniform bool algo;
uniform int iterations;


uniform sampler2D input1;

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
		
		
		
		
	color = getColPixel0.rgb;
	float colorBuffer;
	int count=0;
	for (int x = 0; x <=iterations; x++)
	{
		for (int y = 1; y<= iterations; y++)
		{
			st1.x = (gl_FragCoord.x+x) / adsk_result_w;
			st1.y = (gl_FragCoord.y+y) / adsk_result_h;
			if ( (gl_FragCoord.x+x) >=0 && (gl_FragCoord.x+x) <= adsk_result_w){getColPixel1 = texture2D(input1, st1);}
			if ( (gl_FragCoord.y+y) >=0 && (gl_FragCoord.y+y) <= adsk_result_h){getColPixel1 = texture2D(input1, st1);}		
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
			if ( (gl_FragCoord.x-x) >=0 && (gl_FragCoord.x-x) <= adsk_result_w){getColPixel1 = texture2D(input1, st1);}
			if ( (gl_FragCoord.y+y) >=0 && (gl_FragCoord.y+y) <= adsk_result_h){getColPixel1 = texture2D(input1, st1);}		
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
			if ( (gl_FragCoord.x+x) >=0 && (gl_FragCoord.x+x) <= adsk_result_w){getColPixel1 = texture2D(input1, st1);}
			if ( (gl_FragCoord.y-y) >=0 && (gl_FragCoord.y-y) <= adsk_result_h){getColPixel1 = texture2D(input1, st1);}		
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
			if ( (gl_FragCoord.x-x) >=0 && (gl_FragCoord.x-x) <= adsk_result_w){getColPixel1 = texture2D(input1, st1);}
			if ( (gl_FragCoord.y-y) >=0 && (gl_FragCoord.y-y) <= adsk_result_h){getColPixel1 = texture2D(input1, st1);}		
			color += getColPixel1.rgb;
			count++;
		}
		count++;
	}

	color/=count;

	if (algo==true) {
		color += getColPixel0.rgb;
		color /= 2;
	}

	if (color.r>=color.b && color.r>=color.g ){color.r=1; color.g=0; color.b=0;}
	if (color.g>=color.r && color.g>=color.b ){color.r=0; color.g=1; color.b=0;}
	if (color.b>=color.r && color.b>=color.g ){color.r=0; color.g=0; color.b=1;}

	vec4 outColor;
	gl_FragColor =  vec4(color,1.0);
}
