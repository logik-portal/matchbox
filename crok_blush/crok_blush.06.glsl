#version 120
// loading high blur and low blur doing the bandpass
uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1, adsk_results_pass3, adsk_results_pass5;
uniform float gain, contrast, saturation;
uniform int output_selection;

// Real contrast adjustments by  Miles
vec3 adjust_contrast(vec3 col, vec4 con){
vec3 c = con.rgb * vec3(con.a);
vec3 t = (vec3(1.0) - c) / vec3(2.0);
t = vec3(.18);
col = (1.0 - c.rgb) * t + c.rgb * col;
return col;
}

vec3 adjust_saturation(vec3 rgb, float adjustment)
{
    // Algorithm from Chapter 16 of OpenGL Shading Language
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
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

void main(void)
{
	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec3 h_blur = texture2D(adsk_results_pass3, uv).rgb;
	vec3 l_blur = texture2D(adsk_results_pass5, uv).rgb;
  vec3 f = texture2D(adsk_results_pass1, uv).rgb;
  float m = texture2D(adsk_results_pass1, uv).a;

	//doing the bandpass
	vec3 c = l_blur - h_blur;

	//adjust gain
	c *= gain;

	// adjust contrast
	c = adjust_contrast(c, vec4(contrast));

  // adjust saturation
  c = adjust_saturation(c, saturation);

  // output bandpass only
  if( output_selection == 0 ){
    // add a pure gray to it
    c = c;
  }

  // output bandpass + pure gray
  else if( output_selection == 1 ){
    // add a pure gray to it
    c += 0.5;
  }

  else if( output_selection == 2 ){
    // overlay processed front and original via matte
    c += 0.5;
    c = overlay( c, f );
    c = vec3(m * c + (1.0 - m) * f);
  }

	gl_FragColor = vec4(c, m);
}
