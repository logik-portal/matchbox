// https://github.com/glslio/glsl-transition/tree/master/example/transitions

uniform float adsk_result_w, adsk_result_h, adsk_time;
uniform float adsk_result_frameratio;
vec2 resolution = vec2(adsk_result_w, adsk_result_h);
float time = adsk_time * 0.05;

// General parameters
uniform sampler2D from;
uniform sampler2D to;
uniform float pr;
uniform int transition;
uniform float smoothness;
uniform float expo;

float ga = 17.5;
float br = 1.74;

const vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
const vec2 boundMin = vec2(0.0, 0.0);
const vec2 boundMax = vec2(1.0, 1.0);
const float PI = 3.141592653589793;
float rand (vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// circle_open
uniform bool opening;
uniform float circle_smoothness;
const vec2 center = vec2(0.5, 0.5);
const float SQRT_2 = 1.414213562373;
uniform float circle_aspect;

// blur
uniform int BLUR_QUALITY;
uniform float blur_size;
const float GOLDEN_ANGLE = 2.399963229728653; // PI * (3.0 - sqrt(5.0))
vec4 blur(sampler2D t, vec2 c, float radius) {
  vec4 sum = vec4(0.0);
  float q = float(BLUR_QUALITY);
  // Using a "spiral" to propagate points.
  for (int i=0; i<BLUR_QUALITY; ++i) {
    float fi = float(i);
    float a = fi * GOLDEN_ANGLE;
    float r = sqrt(fi / q) * radius;
    vec2 p = c + r * vec2(cos(a), sin(a));
    sum += texture2D(t, p);
  }
  return sum / q;
}

vec3 from_log(vec3 col)
{
	if (col.r >= 0.0) {
		col.r = pow((col.r + br), ga);
	}
	if (col.g >= 0.0) {
		col.g = pow((col.g + br), ga);
	}
	if (col.b >= 0.0) {
		col.b = pow((col.b + br), ga);
	}
	return col;
}

vec3 to_log(vec3 col)
{
    if (col.r >= 0.0) {
    	col.r = (pow(col.r, 1.0 / ga)) - br;
	}
    if (col.g >= 0.0) {
    	col.g = (pow(col.g, 1.0 / ga)) - br;
	}
    if (col.b >= 0.0) {
    	col.b = (pow(col.b, 1.0 / ga)) - br;
	}
    return col;
}
// fade grayscale
uniform float grayPhase; // if 0.0, the image directly turn grayscale, if 0.9, the grayscale transition phase is very important
vec3 grayscale (vec3 color) {
  return vec3(0.2126*color.r + 0.7152*color.g + 0.0722*color.b);
}

// fade greg-paul
uniform float sat_gregPhase; // if 0.0, the image directly turn grayscale, if 0.9, the grayscale transition phase is very important
uniform float gregExpos;
vec3 graypaul (vec3 color)
{
  color = vec3(0.2126*color.r + 0.7152*color.g + 0.0722*color.b);
   return color;
}

// fade to color
uniform vec3 color;
uniform float colorPhase; // if 0.0, there is no black phase, if 0.9, the black phase is very important

// flash
uniform float fp; // if 0.0, the image directly turn grayscale, if 0.9, the grayscale transition phase is very important
uniform float fi;
uniform float fze;
uniform vec3 fcol; // vec3(1.0, 0.8, 0.3)
uniform float fv; // 3.0

// squares
uniform float squares_size;
uniform float squares_smoothness;
uniform float squares_aspect;

// wipe
// uniform vec2 wipe_direction;
uniform float wipe_smoothness;
uniform float angle;

// morph
uniform float morph_strength;

// cross zoom
uniform float cz_strength;

// dreamy
uniform float amount;
uniform float detail;
uniform float speed;
uniform int wave_direction;

float Linear_ease(in float begin, in float change, in float duration, in float time) {
    return change * time / duration + begin;
}

float Exponential_easeInOut(in float begin, in float change, in float duration, in float time) {
    if (time == 0.0)
        return begin;
    else if (time == duration)
        return begin + change;
    time = time / (duration / 2.0);
    if (time < 1.0)
        return change / 2.0 * pow(2.0, 10.0 * (time - 1.0)) + begin;
    return change / 2.0 * (-pow(2.0, -10.0 * (time - 1.0)) + 2.0) + begin;
}

float Sinusoidal_easeInOut(in float begin, in float change, in float duration, in float time) {
    return -change / 2.0 * (cos(PI * time / duration) - 1.0) + begin;
}

/* random number between 0 and 1 */
float hash(in vec3 scale, in float seed) {
    /* use the fragment position for randomness */
    return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
}

vec3 crossFade(in vec2 uv, in float dissolve) {
    return mix(texture2D(from, uv).rgb, texture2D(to, uv).rgb, dissolve);
}

// Slide
uniform int slide_direction;

// Radial
uniform int radial_center;
uniform float radial_smoothness;

// Simple Flip
uniform int flip_direction;

// BCC Misalignment / BCC Tritone Dissolve
uniform float vertJerkOpt;
uniform float rgbOffsetOpt;
uniform float horzFuzzOpt;
uniform float zoom;

// 2 colour uniforms
uniform float t_amount, exposure;
uniform float dark_low, dark_high, light_low, light_high;
uniform float brightness, contrast, saturation;
uniform vec3 light_tint, dark_tint;
const vec3 lumc = vec3(0.2125, 0.7154, 0.0721);
const vec3 avg_lum = vec3(0.5, 0.5, 0.5);

vec3 tint(vec3 col)
{
	float bri = (col.x+col.y+col.z)/3.0;
	float v = smoothstep(dark_low, dark_high, bri);
	col = mix(dark_tint * bri, col, v);
	v = smoothstep(light_low, light_high, bri);
	col = mix(col, min(light_tint * col, 1.0), v);
	vec3 intensity = vec3(dot(col.rgb, lumc));
	vec3 sat_color = mix(intensity, col.rgb, saturation);
	vec3 con_color = mix(avg_lum, sat_color, contrast);
	return (con_color - 1.0 + brightness) * exposure;
}

// Noise generation functions borrowed from:
// https://github.com/ashima/webgl-noise/blob/master/src/noise2D.glsl

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}


void main() {
  vec2 p = gl_FragCoord.xy / resolution.xy;
  vec4 fcc = texture2D(from, p);
  vec4 tcc = texture2D(to, p);
  vec4 c = vec4(0.0);
// fade
  if ( transition == 0)
  {
	  gl_FragColor = mix(texture2D(from, p), texture2D(to, p), pr);
  }

// fade grayscale
  else if ( transition == 1)
  {
	  gl_FragColor = mix(mix(vec4(grayscale(fcc.rgb), 1.0), texture2D(from, p), smoothstep(1.0-grayPhase, 0.0, pr)), mix(vec4(grayscale(tcc.rgb), 1.0), texture2D(to, p), smoothstep(grayPhase, 1.0, pr)), pr);
  }

  // fade Greg-Paul
    else if ( transition == 12)
    {
      // incoming
      vec3 from_c = mix(graypaul(fcc.rgb), fcc.rgb, smoothstep(1.0-sat_gregPhase * -0.5, 0.0, pr));
      // exposure adjustemnt
      from_c = from_log(from_c);
      from_c = from_c * pow(1.3, expo * pr);
      from_c = to_log(from_c);

      // outgoing
      vec3 to_c = mix(graypaul(tcc.rgb), tcc.rgb, smoothstep(sat_gregPhase * -0.5, 1.0, pr));
      // exposure adjustemnt
      to_c = from_log(to_c);
      to_c = to_c * pow(1.3, expo * (1.0 - pr));
      to_c = to_log(to_c);

      //final mixing
      c.rgb = mix(from_c, to_c, pr);
      if ( tcc.rgb == vec3(0.0) )
        c.rgb = from_c;

      gl_FragColor = c;
    }

// fade to color
  else if ( transition == 2)
	  gl_FragColor = mix(mix(vec4(color, 1.0), texture2D(from, p), smoothstep(1.0-colorPhase, 0.0, pr)), mix(vec4(color, 1.0), texture2D(to, p), smoothstep(colorPhase, 1.0, pr)), pr);

// flash
  else if ( transition == 3)
  {
    vec2 p = gl_FragCoord.xy / resolution.xy;
    float i = mix(1.0, 2.0*distance(p, vec2(0.5, 0.5)), fze) * fi * pow(abs(smoothstep(fp, 0.0, distance(vec2(0.5), vec2(pr)))), fv);
    vec4 c = mix(texture2D(from, p), texture2D(to, p), smoothstep(0.5*(1.0-fp), 0.5*(1.0+fp), pr));
    c += i * vec4(fcol, 1.0);
    gl_FragColor = c;
  }

// blur
  else if ( transition == 4)
  {
	  float inv = 1.-pr;
	  gl_FragColor = inv*blur(from, p, pr*blur_size * .01) + pr*blur(to, p, inv*blur_size * .01);
  }

// circle open
  else if ( transition == 5)
  {
    /*
    float pro = pr * adsk_result_frameratio / circle_aspect;
    vec2 pp = p;
    pp -= vec2(0.5);
    pp.x *= adsk_result_frameratio / circle_aspect;
    pp += vec2(0.5);
    */
    float x = opening ? pr : 1.-pr;
	  float m = smoothstep(- circle_smoothness, 0.0, SQRT_2*distance(center, p) - x * (1.+circle_smoothness));
	  gl_FragColor = mix(texture2D(from, p), texture2D(to, p), opening ? 1.-m : m);
  }

// morph
  else if ( transition == 6)
  {
	  vec4 ca = texture2D(from, p);
	  vec4 cb = texture2D(to, p);

	  vec2 oa = (((ca.rg+ca.b)*0.5)*2.0-1.0);
	  vec2 ob = (((cb.rg+cb.b)*0.5)*2.0-1.0);
	  vec2 oc = mix(oa,ob,0.5)*morph_strength;

	  float w0 = pr;
	  float w1 = 1.0-w0;
	  gl_FragColor = mix(texture2D(from, p+oc*w0), texture2D(to, p-oc*w1), pr);
  }

// cross zoom
  else if ( transition == 7)
  {
	  vec2 center = vec2(Linear_ease(0.25, 0.5, 1.0, pr), 0.5);
	  float dissolve = Exponential_easeInOut(0.0, 1.0, 1.0, pr);
	  float strength = Sinusoidal_easeInOut(0.0, cz_strength, 0.5, pr);
	  vec3 color = vec3(0.0);
	  float total = 0.0;
	  vec2 toCenter = center - p;
	  float offset = hash(vec3(12.9898, 78.233, 151.7182), 0.0);

	  for (float t = 0.0; t <= 40.0; t++) {
		  float percent = (t + offset) / 40.0;
		  float weight = 4.0 * (percent - percent * percent);
		  color += crossFade(p + toCenter * percent * strength, dissolve) * weight;
		  total += weight;
		  gl_FragColor = vec4(color / total, 1.0);
	  }
  }

// Slide
  else if ( transition == 8)
  {
	  float translateX = 0.0;
	  float translateY = -1.0;

	  if ( slide_direction == 0 ) // Slide Down
	  {
		  translateX = 0.0;
		  translateY = -1.0;
	  }
	  if ( slide_direction == 1 ) // Slide Left
	  {
		  translateX = -1.0;
		  translateY = 0.0;
	  }
	  if ( slide_direction == 2 ) // Slide Right
	  {
		  translateX = 1.0;
		  translateY = 0.0;
	  }
	  if ( slide_direction == 3 ) // Slide Up
	  {
		  translateX = 0.0;
		  translateY = 1.0;
	  }

	  float x = pr * translateX;
	  float y = pr * translateY;

	  if (x >= 0.0 && y >= 0.0) {
		  if (p.x >= x && p.y >= y) {
			  gl_FragColor = texture2D(from, p - vec2(x, y));
		  }
		  else {
			  vec2 uv;
			  if (x > 0.0)
				  uv = vec2(x - 1.0, y);
			  else if (y > 0.0)
				  uv = vec2(x, y - 1.0);
			  gl_FragColor = texture2D(to, p - uv);
        }
    }
	else if (x <= 0.0 && y <= 0.0) {
		if (p.x <= (1.0 + x) && p.y <= (1.0 + y))
			gl_FragColor = texture2D(from, p - vec2(x, y));
		else {
			vec2 uv;
			if (x < 0.0)
				uv = vec2(x + 1.0, y);
			else if (y < 0.0)
				uv = vec2(x, y + 1.0);
			gl_FragColor = texture2D(to, p - uv);
		}
    }
	else
		gl_FragColor = vec4(0.0);
}

// Radial
	else if ( transition == 9)
	{
		vec2 rp = p*2.-2.;
		float a = atan(rp.y, rp.x);

 		if ( radial_center == 0 )  // center
		{
			rp = p*-2.+1.;
			a = atan(rp.x, rp.y);
		}
		else if ( radial_center == 1 )  // bottom left corner
		{
			rp = p;
			a = atan(rp.x, rp.y);
		}
		else if ( radial_center == 2 )  // bottom left corner invert
		{
			rp = p;
			a = atan(rp.y, rp.x);
		}
		else if ( radial_center == 3 )  // top right corner
		{
			rp = p*1.-1.;
			a = atan(rp.x, rp.y);
		}
		else if ( radial_center == 4 )  // top right corner invert
		{
			rp = p*1.-1.;
			a = atan(rp.y, rp.x);
		}
		else if ( radial_center == 5 )  // Soft L / R
		{
			rp = p*1.+1.;
			a = atan(rp.x, rp.y);
		}
		else if ( radial_center == 6 )  // Soft R / L
		{
			rp = p*1.+1.;
			a = atan(rp.y, rp.x);
		}

		float pa = pr*PI*2.5-PI*1.25;
		vec4 fromc = texture2D(from, p);
		vec4 toc = texture2D(to, p);
		if(a>pa) {
			gl_FragColor = mix(toc, fromc, smoothstep(0.0, 0.009 + radial_smoothness, (a-pa)));
		} else {
			gl_FragColor = toc;
		}
	}
// Simple Flip
    else if ( transition == 10)
    {
		vec2 q = p;

		if ( flip_direction == 0 )
		{
			p.y = (p.y - 0.5)/abs(pr - 0.5)*0.5 + 0.5;
			vec4 a = texture2D(from, p);
			vec4 b = texture2D(to, p);
			gl_FragColor = vec4(mix(a, b, step(0.5, pr)).rgb * step(abs(q.y - 0.5), abs(pr - 0.5)), 1.0);
		}
		else if ( flip_direction == 1 )
		{
		     p.x = (p.x - 0.5)/abs(pr - 0.5)*0.5 + 0.5;
		     vec4 a = texture2D(from, p);
		     vec4 b = texture2D(to, p);
		     gl_FragColor = vec4(mix(a, b, step(0.5, pr)).rgb * step(abs(q.x - 0.5), abs(pr - 0.5)), 1.0);
		}
	}


// squares
  else if ( transition == 11)
  {
	  vec2 sq_size = vec2(squares_size);
	  vec2 a_size = vec2(sq_size.x * adsk_result_frameratio / squares_aspect, sq_size.x );
	  float r = rand(floor(vec2(a_size) * p));
	  float m = smoothstep(0.0, -squares_smoothness, r - (pr * (1.0 + squares_smoothness)));
	  gl_FragColor = mix(texture2D(from, p), texture2D(to, p), m);
  }

// wipe
    else if ( transition == 15)
	{
		vec2 wipe_direction = vec2(cos(angle), sin(angle));
		vec2 v = normalize(wipe_direction);
	    v /= abs(v.x)+abs(v.y);
	    float d = v.x * center.x + v.y * center.y;
	    float m = smoothstep(- wipe_smoothness, 0.0, v.x * p.x + v.y * p.y - (d-0.5+pr*(1.0+ wipe_smoothness)));
	    gl_FragColor = mix(texture2D(to, p), texture2D(from, p), m);
	}

// dreamy
    else if ( transition == 16)
	{
		if ( wave_direction == 0 )
		{
			float y = sin((p.y + time * speed *.1) * amount ) * detail *0.0118 * sin( pr / 0.32 );
			gl_FragColor = mix(texture2D(from, (p + vec2(y, 0.0))), texture2D(to, (p + vec2(y, 0.0))), pr);
		}
		else if ( wave_direction == 1 )
		{
			float x = sin((p.x + time * speed *.1) * amount ) * detail *0.0118 * sin( pr / 0.32 );
			gl_FragColor = mix(texture2D(from, (p + vec2(0.0, x))), texture2D(to, (p + vec2(0.0, x))), pr);
		}
	}
  // BCC Misalignment / BCC Tritone Dissolve
      else if ( transition == 17)
  	{
      vec2 uv =  gl_FragCoord.xy/resolution.xy;
      vec2 f_uv = uv;
      vec2 b_uv = uv;
      f_uv -= 0.5;
      b_uv -= 0.5;
      f_uv *= 1.0 - pr * zoom;
      b_uv *= 1.0 - zoom + pr * zoom;
      f_uv += 0.5;
      b_uv += 0.5;

      vec3 color = vec3(0.0);
    	float fuzzOffset = snoise(vec2(time*15.0,uv.y*80.0))*0.003;
    	float largeFuzzOffset = snoise(vec2(time*1.0,uv.y*25.0))*0.004;
    	float f_xoff = (fuzzOffset + largeFuzzOffset) * horzFuzzOpt * pr;
      float b_xoff = (fuzzOffset + largeFuzzOffset) * horzFuzzOpt * (1.0 - pr);

      float f_red = texture2D(	from, 	vec2(f_uv.x + f_xoff -0.01*rgbOffsetOpt * pr, f_uv.y)).r;
    	float f_green = texture2D(	from, 	vec2(f_uv.x + f_xoff,	  f_uv.y)).g;
    	float f_blue = texture2D(	from, 	vec2(f_uv.x + f_xoff +0.01*rgbOffsetOpt * pr, f_uv.y)).b;

      float b_red = texture2D(	to, 	vec2(b_uv.x + b_xoff -0.01*rgbOffsetOpt * (1.0 - pr), b_uv.y)).r;
      float b_green = texture2D(	to, 	vec2(b_uv.x + b_xoff,	  b_uv.y)).g;
      float b_blue = texture2D(	to, 	vec2(b_uv.x + b_xoff +0.01*rgbOffsetOpt * (1.0 - pr), b_uv.y)).b;

    	vec3 f_col = vec3(f_red,f_green,f_blue);
      vec3 b_col = vec3(b_red,b_green,b_blue);

      vec3 ff_col = f_col;
    	ff_col = tint(ff_col);
    	ff_col = mix(f_col, ff_col, t_amount * pr);

      vec3 bb_col = b_col;
      bb_col = tint(bb_col);
      bb_col = mix(b_col, bb_col, t_amount * (1.0 - pr));

      if ( pr < 0.5 )
        color = ff_col ;
      else if ( pr >= 0.5 )
        color = bb_col;
    	gl_FragColor = vec4(color,1.0);
  	}
}
