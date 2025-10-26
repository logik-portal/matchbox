//By Nestor Vina
//based on https://www.shadertoy.com/view/Mty3DV

uniform sampler2D front, depth;
uniform float adsk_result_w, adsk_result_h, adsk_time;
float iGlobalTime = adsk_time *.05;

// ray marching
const int max_iterations = 70;
const float stop_threshold = 0.0010;
const float grad_step = 0.05;
const float clip_far = 70.0;

// math
const float PI = 3.14159265359;
const float DEG_TO_RAD = PI / 180.0;

vec3 sunDir = normalize(vec3(1.0,-1.0,1.0));


vec3 rotate( vec3 p, vec3 rot ){
    rot.z = -rot.z;
    mat3 ry = mat3(cos(rot.y), 0.0,-sin(rot.y),
			   0.0, 1.0, 0.0,
			   sin(rot.y), 0.0, cos(rot.y)  );

	mat3 rz = mat3(cos(rot.z),-sin(rot.z), 0.0,
			   sin(rot.z), cos(rot.z), 0.0,
			   0.0, 0.0, 1.0 );

	mat3 rx = mat3(1.0, 0.0, 0.0,
			   0.0, cos(rot.x), sin(rot.x),
			   0.0,-sin(rot.x), cos(rot.x) );
    return p*rz*ry*rx;
}


float cubes( vec3 p, vec3 b,float c )
{
  p += vec3(0.0,22.0,0.0);
  p = rotate(p,vec3(-PI*0.135,0.0,0.0));
  vec3 initialp = p;
  p.xz = mod(p.xz,c) - 0.5 * c;
  vec2 index = floor(initialp.xz/c);

  float incidence = length(index)*0.1;
  incidence += sin((index.x + index.y)*0.1 + iGlobalTime*0.1)*0.03;

  p = rotate(p,vec3(iGlobalTime*incidence,iGlobalTime*incidence,0.0));

  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

//Map
vec2 mapCubeSkin(vec3 p){
    float c = 1.0;
    vec2 index = floor(p.xz/c);
    float minDist = cubes(p,vec3(0.5,0.5,.5),c);
   	float color = (1.0+sin(length(index.xy)*0.2+iGlobalTime))*0.5;
	return vec2(minDist, color);
}
vec2 map( vec3 p) {
    p.y += sin((p.x+p.z)*0.3+iGlobalTime*3.0);
    return mapCubeSkin(p);
}

vec2 rayMarching( vec3 origin, vec3 dir, float start, float end ) {

    float depth = start;
	for ( int i = 0; i < max_iterations; i++ ) {
        vec2 distResult = map( origin + dir * depth );
		float dist = distResult.x;
		if ( dist < stop_threshold ) {
			return vec2(depth,distResult.y);
		}
		depth += dist;
		if ( depth >= end) {
			return vec2(end,-1.0);
		}
	}
	return vec2(end,-1.0);
}

vec3 ray_dir( float fov, vec2 size, vec2 pos ) {
	vec2 xy = pos - size * 0.5;

	float cot_half_fov = tan( ( 90.0 - fov * 0.5 ) * DEG_TO_RAD );
	float z = size.y * 0.5 * cot_half_fov;
	return normalize( vec3( -xy, -z ) );
}

vec3 normal( vec3 pos ) {
	const vec3 dx = vec3( grad_step, 0.0, 0.0 );
	const vec3 dy = vec3( 0.0, grad_step, 0.0 );
	const vec3 dz = vec3( 0.0, 0.0, grad_step );
	return normalize (
		vec3(
			map( pos + dx ).x - map( pos - dx ).x,
			map( pos + dy ).x - map( pos - dy ).x,
			map( pos + dz ).x - map( pos - dz ).x
		)
	);
}

mat3 rotationXY( vec2 angle ) {
	vec2 c = cos( angle );
	vec2 s = sin( angle );

	return mat3(
		c.y      ,  0.0, -s.y,
		s.y * s.x,  c.x,  c.y * s.x,
		s.y * c.x, -s.x,  c.y * c.x
	);
}

float fresnel(vec3 n, vec3 d, float exp ){
    return pow(1.0-dot(d,n),exp);
}

vec3 material( vec3 v, vec3 n, vec3 eye,float randomIndex ) {
    //Texturing
    vec2 uv = v.xz;

    //vec3 albedo = texture2D(iChannel0,vec2(randomIndex,0.0)).xyz;//vec3(0.5,0.0,0.0);
    vec3 albedo = mix(vec3(.85, 0.9,0.95),vec3(0.05,0.08,0.09),randomIndex);

    vec3 viewDir = normalize(eye-v);
    //vec3 fresnelColor = vec3(0.0) * fresnel(n,viewDir,1.0);

    float diffuse = dot(sunDir,n)*0.1;
    vec3 ambient = vec3(0.00,0.03,0.1);

    return albedo+diffuse+ambient;
}

void main()
{
	// default ray dir
	vec3 dir = ray_dir( (sin(iGlobalTime * .1) * 10.0 + 30.), vec2(adsk_result_w, adsk_result_h), gl_FragCoord.xy );

	// default ray origin
	vec3 eye = vec3( sin(iGlobalTime * 0.235 + 50.0)* 15.0, -8.0, 45.0 );

	// rotate camera
	mat3 rot = rotationXY( vec2(0,2.0*PI));
	dir = rot * dir;
	eye = rot * eye;

	// ray marching
  vec2 rayResult = rayMarching( eye, dir, 2.0, clip_far );
	float depth = rayResult.x;
	if ( depth >= clip_far ) {
		gl_FragColor = vec4(0.3,0.3,0.3,depth);//Background color
        return;
	}

	// shading
	vec3 pos = eye + dir * depth;
	vec3 n = normal( pos );
  vec3 fogColor = vec3(0.3,0.3,0.3);

  gl_FragColor = vec4(material( pos, n, eye,rayResult.y ), depth);

}
