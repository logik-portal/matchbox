#ifdef GL_ES
precision mediump float;
#endif

uniform float adsk_time;
uniform float adsk_result_w,adsk_result_h;
uniform vec2 CENTER;
uniform float BLADES;
uniform float BIAS;
uniform float SHARPNESS;
uniform vec3 COLOR;
uniform vec3 BKG;
uniform float SPEED;
float time = adsk_time * SPEED;
vec2 rezolution = vec2 (adsk_result_w, adsk_result_h);

void main( void ) {

vec2 position = (( gl_FragCoord.xy / rezolution.xy ) - CENTER) / vec2(rezolution.y/rezolution.x,1.0);
vec3 color = vec3(0.);

float blade = clamp(pow(sin(time+atan(position.y,position.x)*BLADES)+BIAS, SHARPNESS), 0.0, 1.0);

color = mix(vec3(COLOR), vec3(BKG), blade);

gl_FragColor = vec4( color, 1.0 );

}
