uniform sampler2D adsk_results_pass6;
uniform float adsk_time;
uniform float adsk_result_w, adsk_result_h;
float pScanline = 0.6;
float pSlowscan = 0.01;
float pColorshift_x = 0.1;
float pColorshift_y = 0.1;
float pVignettessoftness = 03.59;
float pVignettescale = 01.45;
bool pAddGrain = true;
float grain_opacity = 5.0;
float g_saturation = 0.0;
float pFrequency = 0.2;
float pDistort = 0.4;
float timer = 2.0;
float speed = 2.0;
float Distort =1.0;
float Scale = 1.1;
float stripes_count = 0.3;
float Opacity = 7.0;
float bars_count = 10.0;
float opacity_moire = 1.0;
float moire_scale = 0.2;
float tv_lines = 2.5;
float tv_lines_opacity = 1.0;
float tv_tube_vignette_scale = 1.0;
float tv_dots = 1.0;
float tv_dots_blend = 1.0;
float bw_threshold = 0.2;

bool vhs_bars = true;
bool vhs_stripes= true;
bool moire= true;
bool add_vignette= false;
bool tv_tube_vignette= false;
bool tv_tube_lines= true;
bool tube_moire= true;
bool rgb_offset= true;
bool b_w= false;
bool vcr_distortion= true;
bool slow_scan, scanline_scan, tube_distortion, scanline_distort = true;

uniform vec3 monochrome;


vec2 iResolution = vec2(adsk_result_w, adsk_result_h);
float iGlobalTime = adsk_time*.05;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}


vec3 noise(vec2 uv) {
	vec2 c = (iResolution.x)*vec2(1.,(iResolution.y/iResolution.x));
	vec3 col = vec3(0.0);
	uv.y = uv.y;
   	float r = rand(vec2((2.+iGlobalTime) * floor(uv.x*c.x)/c.x, (2.+iGlobalTime) * floor(uv.y*c.y)/c.y ));
   	float g = rand(vec2((5.+iGlobalTime) * floor(uv.x*c.x)/c.x, (5.+iGlobalTime) * floor(uv.y*c.y)/c.y ));
   	float b = rand(vec2((9.+iGlobalTime) * floor(uv.x*c.x)/c.x, (9.+iGlobalTime) * floor(uv.y*c.y)/c.y ));

	col = vec3(r,g,b);

	return col;
}

float overlay( float s, float d )
{
	return (d < 0.5) ? 2.0 * s * d : 1.0 - 2.0 * (1.0 - s) * (1.0 - d);
}

vec3 overlay( vec3 s, vec3 d )
{
	vec3 c;
	c.x = overlay(s.x,d.x);
	c.y = overlay(s.y,d.y);
	c.z = overlay(s.z,d.z);
	return c;
}


float rand(float c){
	return rand(vec2(c,1.0));
}

float ramp(float y, float start, float end)
{
	float inside = step(start,y) - step(end,y);
	float fact = (y-start)/(end-start)*inside;
	return (1.-fact) * inside;
}

float scanline(vec2 uv)
{
	return sin(iResolution.y * uv.y * pScanline - iGlobalTime * 10.0);
}

float slowscan(vec2 uv) {
	return sin(iResolution.y * uv.y * pSlowscan + iGlobalTime * 6.0);
}


vec2 crt(vec2 coord, float bend)
{
	coord = (coord - 0.5) * 2. / Scale;
	coord *= 0.5;
	coord.x *= 1.0 + pow((abs(coord.y) / bend * Distort), 2.0);
	coord.y *= 1.0 + pow((abs(coord.x) / bend * Distort), 2.0);
	coord  = (coord / 1.0) + 0.5;
	return coord;
}


vec2 scandistort(vec2 uv) {
	float scan1 = clamp(cos(uv.y * speed + iGlobalTime*timer), 0.0, 1.0);
	float scan2 = clamp(cos(uv.y * speed + iGlobalTime*timer + 4.0) * 10.0, 0.0, 1.0) ;
	float amount = scan1 * scan2 * uv.x;
	uv.x -= pDistort * mix(texture2D(adsk_results_pass6, vec2(uv.x, amount)).r * amount, amount, 0.9);
	return uv;
}


// added today
float onOff(float a, float b, float c)
{
	return step(c, sin(iGlobalTime + a*cos(iGlobalTime*b)));
}

vec3 getVideo(vec2 uv)
{
	vec2 look = uv;
	float window = 1./(1.+20.*(look.y-mod(iGlobalTime/4.,1.))*(look.y-mod(iGlobalTime/4.,1.)));
	look.x = look.x + sin(look.y*10. + iGlobalTime)/50.*onOff(4.,4.,.3)*(1.+cos(iGlobalTime*80.))*window;
	float vShift = 0.4*onOff(2.,3.,.9)*(sin(iGlobalTime)*sin(iGlobalTime*20.) +
										 (0.5 + 0.1*sin(iGlobalTime*200.)*cos(iGlobalTime)));
	look.y = mod(look.y + vShift, 1.);
	vec3 video = vec3(texture2D(adsk_results_pass6,look));
	return video;
}

vec2 screenDistort(vec2 uv)
{
	uv -= vec2(.5,.5);
	uv = uv*1.2*(1./1.2+2.*uv.x*uv.x*uv.y*uv.y);
	uv += vec2(.5,.5);
	return uv;
}

// end added today

float vignette(vec2 uv) {
	uv = (uv - 0.5) * 0.95;
	return clamp(pow(cos(uv.x * 3.1415), pVignettescale) * pow(cos(uv.y * 3.1415), pVignettescale) * pVignettessoftness, 0.0, 1.0);
}

float stripes(vec2 uv)
{
	float noi = rand(uv*vec2(0.5,1.) + vec2(1.,3.)) * Opacity;
	return ramp(mod(uv.y* stripes_count + iGlobalTime/2.+sin(iGlobalTime + sin(iGlobalTime* 2.)),1.),0.5,0.6)*noi;
}


void main(void)
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
	vec2 uv2 = gl_FragCoord.xy / iResolution.xy*2.-1.;
	vec2 uv3 = gl_FragCoord.xy / iResolution.xy*2.-1.;
	vec3 grain = noise(uv);
	vec3 grau = vec3 (0.5);

	vec2 sd_uv = uv;
	if ( scanline_distort )
		sd_uv = scandistort(uv);

	vec2 crt_uv = sd_uv;

	if ( tube_distortion )
		crt_uv = crt(sd_uv, 2.0);

	vec4 color = texture2D(adsk_results_pass6, crt_uv).rgba;
	vec4 scanline_color = color;
	vec4 slowscan_color = color;

	if ( vcr_distortion )
	{
		color = vec4(getVideo(crt_uv), 1.0);
	}

	if ( scanline_scan )
		scanline_color = vec4(scanline(crt_uv));

	if ( slow_scan )
		slowscan_color = vec4(slowscan(crt_uv));


	if(tube_moire)
		{
		color*=1.00+tv_dots_blend*.2*sin(crt_uv.x*float(iResolution.x*5.0*tv_dots));
		color*=1.00+tv_dots_blend*.2*cos(crt_uv.y*float(iResolution.y))*sin(0.5+crt_uv.x*float(iResolution.x));
		}

	if ( vhs_stripes )
		color *= (1.0 + stripes(crt_uv));
	if ( vhs_bars)
		color *= (12. + mod(crt_uv.y * bars_count + iGlobalTime,1.))/13.;
	if ( moire )
		color *= (.45+(rand(crt_uv * .01 * moire_scale)) * opacity_moire);
	if ( pAddGrain )
	{
		grain = mix(grau, grain, grain_opacity * .1);
		vec3 bw_grain = vec3(grain.r);
		grain = mix(bw_grain, grain, g_saturation);
		color = vec4(overlay(grain, vec3(color)), 1.0);
	}
	if ( add_vignette )
		color *= vignette(uv);
	if ( tv_tube_vignette )
		color*=1.-pow(length(uv2*uv2*uv2*uv2)*1., 6. * 1./tv_tube_vignette_scale);
	if ( tv_tube_lines )
	{
		crt_uv.y *= iResolution.y / iResolution.y * tv_lines;
		color.r*=(.55+abs(.5-mod(crt_uv.y     ,.021)/.021) * tv_lines_opacity) *1.2;
		color.g*=(.55+abs(.5-mod(crt_uv.y+.007,.021)/.021) * tv_lines_opacity) *1.2;
		color.b*=(.55+abs(.5-mod(crt_uv.y+.014,.021)/.021) * tv_lines_opacity) *1.2;
	}


	color = mix(color, mix(scanline_color, slowscan_color, 0.5), 0.05);

  float blend_anim2 = smoothstep(0., 10., iGlobalTime - .25);
  float closing = smoothstep(10., 0., iGlobalTime - 190.);

  // add letterbox
  float offset = 0.0;
  color *= step(abs(uv.y - 0.5 + offset), blend_anim2 * .3);
  color *= step(abs(uv.y - 0.5 + offset), closing * .3);

	gl_FragColor = color.rgba;
}
