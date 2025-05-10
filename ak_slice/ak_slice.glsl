// with some inspiration from crok_gradient

uniform float adsk_result_w, adsk_result_h;
uniform vec2 Point1, Point2;
uniform sampler2D Front;
uniform bool ShowBG;
uniform bool ShowFG;
uniform float BGOpacity;
uniform float FGOpacity;

vec4 adsk_getBlendedValue(int BlendType,vec4 srcColor,vec4 dstColor);

int blend_type = 0;  // Add

vec2 resolution = vec2(adsk_result_w,adsk_result_h);
float line_overlay = 0.2;
float bg_overlay   = BGOpacity;
float pix_threshold = 0.0001;

// from: https://www.shadertoy.com/view/MlcGDB
float linesegment(vec2 uv,vec2 p1,vec2 p2,float r) 
{
  vec2 g = p2 - p1;
  vec2 h = uv - p1;

  float d = length(h - g * clamp(dot(g,h) / dot(g,g),0.0,1.0)); 
  return(smoothstep(r,0.5*r,d));
}

// from https://math.stackexchange.com/questions/175896/finding-a-point-along-a-line-a-certain-distance-away-from-another-point
vec2 pt_from_line_v2(vec2 p1,vec2 p2,float dt)
{
  float m = (p2.y - p1.y)/(p2.x - p1.x);
  float x = p1.x + dt / sqrt(1 + m*m);
  float y = m * (x - p1.x) + p1.y;

  return(vec2(x,y));
}

void main()
{
	vec2 uv 						= gl_FragCoord.xy / resolution.xy;
	vec3 pixel 					= texture2D(Front,uv).rgb;
  float lwidth    		= max(1.0/adsk_result_w,1.0/adsk_result_h);		// pixel width in float
	
  vec2 p1 						= vec2(Point1.x, Point1.y);
	vec2 p2 						= vec2(Point2.x, Point2.y);
  float d							= distance(p1,p2);

  vec3 bg_col   			= ShowBG? pixel * bg_overlay : vec3(0.0);
  vec3 fg_col   			= vec3(0.0);
  vec3 line_col 			= vec3(1.0);

  float line_opacity  = linesegment(uv,p1,p2,lwidth);

  // add line overlay
  if(line_opacity > pix_threshold)
    bg_col = clamp(adsk_getBlendedValue(blend_type,vec4(bg_col,1.0),vec4(line_col,line_opacity*line_overlay)).rgb,0.0,1.0);

  // compute sample point and determine color overlay
  float xd 					  = d / resolution.x * gl_FragCoord.x;
  vec2 sample_pt		 	= pt_from_line_v2(p1,p2,xd);
  vec3 sample 				= texture2D(Front,sample_pt).rgb;
  vec3 fg_y           = vec3(0.0);

  bool paint = false;

  // if(!StretchTrace && gl_FragCoord.x >= p1.x && gl_FragCoord.x <= p2.x)
  {
    if(abs(sample.r - uv.y) < lwidth)
    {
      fg_col.r = FGOpacity;
      fg_y.r   = uv.y;
      paint    = true;
    }
    if(abs(sample.g - uv.y) < lwidth)
      {
      fg_col.g = FGOpacity;
      fg_y.g   = uv.y;
      paint    = true;
    }
    if(abs(sample.b - uv.y) < lwidth)
    {
      fg_col.b = FGOpacity;
      fg_y.b   = uv.y;
      paint    = true;
    }

    if(gl_FragCoord.x > 0) 
    {
      float xd_prev 				= d / resolution.x * (gl_FragCoord.x-1);
      vec2 sample_pt_prev   = pt_from_line_v2(p1,p2,xd_prev);
      vec3 sample_prev			= texture2D(Front,sample_pt_prev).rgb;

      if(sample.r > sample_prev.r && uv.y > sample_prev.r && uv.y < sample.r ||
         sample.r < sample_prev.r && uv.y < sample_prev.r && uv.y > sample.r)
      {
        fg_col.r = FGOpacity;
        paint    = true;
      }
      if(sample.g > sample_prev.g && uv.y > sample_prev.g && uv.y < sample.g ||
         sample.g < sample_prev.g && uv.y < sample_prev.g && uv.y > sample.g)
      {
        fg_col.g = FGOpacity;
        paint    = true;
      }
      if(sample.b > sample_prev.b && uv.y > sample_prev.b && uv.y < sample.b ||
         sample.b < sample_prev.b && uv.y < sample_prev.b && uv.y > sample.b)
      {
        fg_col.b = FGOpacity;
        paint    = true;
      }
    }
  }

  gl_FragColor = vec4((paint && ShowFG)? fg_col : bg_col,1.0);
}
