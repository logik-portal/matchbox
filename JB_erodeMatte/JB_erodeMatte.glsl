uniform float adsk_result_w;
uniform float adsk_result_h;

uniform sampler2D input1;

uniform bool alias;
uniform int iterations;

void main(void) {

	vec2 st0;
	st0.x = gl_FragCoord.x / adsk_result_w;
	st0.y = gl_FragCoord.y / adsk_result_h;

	vec4 getColPixel0;
	getColPixel0 = texture2D(input1, st0);

	vec3 color;
	vec2 st1, st2, st3, st4, st5, st6, st7, st8;
	vec4 getColPixel1, getColPixel2, getColPixel3, getColPixel4, getColPixel5, getColPixel6, getColPixel7, getColPixel8;

	color = getColPixel0.rgb;
	float colorBuffer;
	int count=0;

	for (int x = 0; x <=iterations; x++)
	{
		for (int y = 1; y<= iterations; y++)
		{
			st1.x = (gl_FragCoord.x+x) / adsk_result_w;
			st1.y = (gl_FragCoord.y+y) / adsk_result_h;
			if ( (gl_FragCoord.x+x) >=0 && (gl_FragCoord.x+x) <= adsk_result_w) {
				getColPixel1 = texture2D(input1, st1);
			}
			if ( (gl_FragCoord.y+y) >=0 && (gl_FragCoord.y+y) <= adsk_result_h) {
				getColPixel1 = texture2D(input1, st1);
			}		
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
			if ( (gl_FragCoord.x-x) >=0 && (gl_FragCoord.x-x) <= adsk_result_w) {
				getColPixel1 = texture2D(input1, st1);
			}
			if ( (gl_FragCoord.y+y) >=0 && (gl_FragCoord.y+y) <= adsk_result_h) {
				getColPixel1 = texture2D(input1, st1);
			}		
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
			if ( (gl_FragCoord.x+x) >=0 && (gl_FragCoord.x+x) <= adsk_result_w) {
				getColPixel1 = texture2D(input1, st1);
			}
			if ( (gl_FragCoord.y-y) >=0 && (gl_FragCoord.y-y) <= adsk_result_h) {
				getColPixel1 = texture2D(input1, st1);
			}		
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
			if ( (gl_FragCoord.x-x) >=0 && (gl_FragCoord.x-x) <= adsk_result_w) {
				getColPixel1 = texture2D(input1, st1);
			}
			if ( (gl_FragCoord.y-y) >=0 && (gl_FragCoord.y-y) <= adsk_result_h) {
				getColPixel1 = texture2D(input1, st1);
			}		
			color += getColPixel1.rgb;
			count++;
		}
		count++;
	}

	color /= count;

	if( ((color.x+color.y+color.z)/3) < 0.33 ) {
		color=vec3(0);
	}
	if( ((color.x+color.y+color.z)/3) >= 0.33 && ((color.x+color.y+color.z)/3) < 0.51) {
		color=getColPixel0.rgb;
		if(alias != false) {
			color=vec3(0.5);
		}
	}
	if( ((color.x+color.y+color.z)/3) >= 0.51) {
		color=vec3(1);
	}

	gl_FragColor = vec4(color,1.0);
}
