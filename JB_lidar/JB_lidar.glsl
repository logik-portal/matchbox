uniform float adsk_result_w;
uniform float adsk_result_h;
uniform sampler2D adsk_previous_frame_input1;
uniform sampler2D adsk_next_frame_input1;

uniform sampler2D input1;
uniform bool lumaColor;
uniform int pixelSize;

void main(void)
{
	vec2 st0;
	st0.x = gl_FragCoord.x / adsk_result_w;
	st0.y = gl_FragCoord.y / adsk_result_h;
	
	vec4 getColPixel0;
	getColPixel0 = texture2D(input1, st0);
	
	float luma = (getColPixel0.r + getColPixel0.g + getColPixel0.b)/3;
	
	vec4 getColPixel1;
	
	getColPixel1 = texture2D(adsk_previous_frame_input1, st0);
	float luma1 = (getColPixel1.r + getColPixel1.g + getColPixel1.b)/3;

	vec4 getColPixel2;
	
	getColPixel2 = texture2D(adsk_next_frame_input1, st0);
	float luma2 = (getColPixel2.r + getColPixel2.g + getColPixel2.b)/3;
	
	float buffer = (luma + luma1 +luma2)/3;
	vec4 FragColor;
	FragColor=vec4(vec3(0),1);
	int pixelRatio;
	pixelRatio = int(luma*20);
	
	if (buffer>= (luma*0.9)){FragColor=vec4(vec3(0),1);}
	if (mod((gl_FragCoord.x+0.5),pixelRatio)>=pixelSize && mod((gl_FragCoord.y+0.5),pixelRatio)>=pixelSize){
	
	if (buffer<(luma*0.9)){
		FragColor = vec4(luma*exp(buffer), luma1*exp(buffer), luma2*exp(buffer),1);
		if (luma >= luma1 && luma >= luma2){FragColor = vec4(1*luma, 0, 0,1);}
		if (luma1 >= luma && luma >= luma2){FragColor = vec4(0, 1*luma, 0,1);}
		if (luma2 >= luma1 && luma >= luma){FragColor = vec4(0, 0, 1*luma,1);};}

	
	;}
	
	if (lumaColor == true){
	
		if (buffer>= (luma*0.9)){FragColor=vec4(vec3(0),1);}
		if (mod((gl_FragCoord.x+0.5),pixelRatio)>=pixelSize && mod((gl_FragCoord.y+0.5),pixelRatio)>=pixelSize){
	
			if (buffer<(luma*0.9)){
			
			FragColor = vec4(luma*exp(buffer), luma1*exp(buffer), luma2*exp(buffer),1);
			FragColor = vec4(getColPixel0.r, getColPixel0.g, getColPixel0.b,1)
			
			;}
		;}
	;}
	
	gl_FragColor = FragColor;
	
}
