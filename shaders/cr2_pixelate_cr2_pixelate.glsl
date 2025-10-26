uniform float adsk_result_w , adsk_result_h;
uniform float lift;
uniform float gain;
uniform float gamma;
uniform float radius;
uniform sampler2D frontTex;




void main(void){

//normalize canvas coordinates
vec2 st;
st.x = gl_FragCoord.x / adsk_result_w;
st.y = gl_FragCoord.y / adsk_result_h;



float dx = 10.*(1./radius);
float dy = 10.*(1./radius);
vec2 coord = vec2(dx*floor(st.x/dx),dy*floor(st.y/dy));


gl_FragColor = (texture2D(frontTex,coord) * gain) + lift;



}



 

