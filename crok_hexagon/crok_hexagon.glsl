// based on https://www.shadertoy.com/view/ls23Dc by pyalot
// http://www.gamedev.net/page/resources/_/technical/game-programming/coordinates-in-hexagon-based-tile-maps-r1800
// nearest hexagon sampling, not quite sure if it's correct
#version 120

uniform sampler2D source;
uniform float adsk_result_w,adsk_result_h, adsk_result_frameratio;
uniform float size, edge, rot;
uniform vec2 offset;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);

float PI = 3.14159265359;
float TAU = 2.0*PI;
float deg30 = TAU/12.0;

float hexDist(vec2 a, vec2 b){
	vec2 p = abs(b-a);
	float s = sin(deg30);
	float c = cos(deg30);

	float diagDist = s*p.x + c*p.y;
	return max(diagDist, p.x)/c;
}

vec2 nearestHex(float s, vec2 st)
{
	float h = sin(deg30)*s;
	float r = cos(deg30)*s;
	float b = s + 2.0*h;
	float a = 2.0*r;
	float m = h/r;

	vec2 sect = st/vec2(2.0*r, h+s);
	vec2 sectPxl = mod(st, vec2(2.0*r, h+s));

	float aSection = mod(floor(sect.y), 2.0);

	vec2 coord = floor(sect);
	if(aSection > 0.0){
		if(sectPxl.y < (h-sectPxl.x*m)){
			coord -= 1.0;
		}
		else if(sectPxl.y < (-h + sectPxl.x*m)){
			coord.y -= 1.0;
		}

	}
	else{
		if(sectPxl.x > r){
			if(sectPxl.y < (2.0*h - sectPxl.x * m)){
				coord.y -= 1.0;
			}
		}
		else{
			if(sectPxl.y < (sectPxl.x*m)){
				coord.y -= 1.0;
			}
			else{
				coord.x -= 1.0;
			}
		}
	}

	float xoff = mod(coord.y, 2.0)*r;
	return vec2(coord.x*2.*r-xoff, coord.y*(h+s))+vec2(r*2.0, s);
}

void main (void)
{
	float s = resolution.x / size;
	vec2 offs = resolution * 0.5 + offset;
	vec2 nearest = nearestHex(s, gl_FragCoord.xy - offs);
	vec4 texel = texture2D(source, (nearest + offs)/resolution.xy);
	float dist = hexDist(gl_FragCoord.xy - offs, nearest);
	float interiorSize = s;
	float interior = 1.0 - smoothstep(interiorSize - edge, interiorSize, dist * edge);
	gl_FragColor = vec4(texel.rgb*interior, 1.0);
}
