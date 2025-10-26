vec3 adsk_getVertexPosition();
vec3 adsk_getCameraPosition();
mat4 adsk_getModelViewInverseMatrix();

const vec3 LumCoeff = vec3(0.2125, 0.7154, 0.0721);

uniform float adskUID_itterations, adskUID_density, adskUID_gain, adskUID_saturation;


vec3 adskUID_fractalNoise(vec3 p){
	p  = fract(p * vec3(5.3983, 5.4427, 6.9371));
    p += dot(p.yzx, p.xyz  + vec3(21.5351, 14.3137, 15.3219));
	return fract(vec3(p.x * p.z * 95.4337, p.x * p.y * 97.597, p.y * p.z * 93.8365));
}

float adskUID_noise(vec3 x)
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.-2.*f);
	
    float n = p.x + p.y*157. + 113.*p.z;
    
    vec4 v1 = fract(753.5453123*sin(n + vec4(0., 1., 157., 158.)));
    vec4 v2 = fract(753.5453123*sin(n + vec4(113., 114., 270., 271.)));
    vec4 v3 = mix(v1, v2, f.z);
    vec2 v4 = mix(v3.xy, v3.zw, f.y);
    return mix(v4.x, v4.y, f.x);
}

vec3 stars(in vec3 p)
{
    vec3 c = vec3(0.0);
    float res = 3000.0;
    
	for (float i=0.;i<adskUID_itterations;i++)
    {
        vec3 q = fract(p*(.15*res))-0.5;
        vec3 id = floor(p*(.15*res));
        float rn = adskUID_fractalNoise(id).z;
        float c2 = 1.-smoothstep(-0.2,.4,length(q));
        c2 *= step(rn,0.005+i*0.014);
        c += c2*(mix(vec3(1.0,0.75,0.5),vec3(0.85,0.9,1.),rn*30.)*0.5 + 0.5);
        p *= 1.15;
    }
	return c*c*1.5 * (adskUID_noise(p *10.01) + 0.5) ;
}


vec4 adskUID_lightbox(vec4 i)
{
    vec4 camera = adsk_getModelViewInverseMatrix() * vec4(adsk_getCameraPosition(), 1.0);
    vec4 vertex = adsk_getModelViewInverseMatrix() * vec4(adsk_getVertexPosition(), 1.0);
    vec3 dir = normalize(vertex.xyz - camera.xyz);
	
    vec3 avg_lum = vec3(0.5);
    vec3 col = stars(dir);
	col *= vec3(adskUID_noise(dir * adskUID_density));
	col = mix(vec3(dot(col, LumCoeff)), col, adskUID_saturation);
	col *= adskUID_gain;
    return vec4( col, 1.0 );
}