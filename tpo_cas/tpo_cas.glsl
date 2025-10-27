//based on CAS (Contrast Adaptive Sharpening) v1.0 https://github.com/GPUOpen-Effects/FidelityFX-CAS
//Converted to Flame matchbox by tpo.comp @ 2023-01-08
//Thanks to Graziella on Logik Live 

uniform sampler2D channel0;
uniform sampler2D channel1;
uniform vec3 mouse;
uniform float time;
uniform vec2 channelResolution[2];
uniform float adsk_result_w, adsk_result_h;

void main()
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/vec2(adsk_result_w, adsk_result_h);
    vec2 muv;
    if (mouse.z > 0.) {
        muv = mouse.xy/vec2(adsk_result_w, adsk_result_h);
    } else {
        muv = vec2(.5+.3*sin(time*.3),.5);
    }
  
    vec3 col = texture(channel0, uv).xyz;

    // CAS algorithm
    float max_g = col.y;
    float min_g = col.y;
    vec4 uvoff = vec4(1,0,1,-1)/channelResolution[0].xxyy;
    vec3 colw;
    vec3 col1 = texture(channel0, uv+uvoff.yw).xyz;
    max_g = max(max_g, col1.y);
    min_g = min(min_g, col1.y);
    colw = col1;
    col1 = texture(channel0, uv+uvoff.xy).xyz;
    max_g = max(max_g, col1.y);
    min_g = min(min_g, col1.y);
    colw += col1;
    col1 = texture(channel0, uv+uvoff.yz).xyz;
    max_g = max(max_g, col1.y);
    min_g = min(min_g, col1.y);
    colw += col1;
    col1 = texture(channel0, uv-uvoff.xy).xyz;
    max_g = max(max_g, col1.y);
    min_g = min(min_g, col1.y);
    colw += col1;
    float d_min_g = min_g;
    float d_max_g = 1.-max_g;
    float A;
    max_g = max(0., max_g);
    if (d_max_g < d_min_g) {
        A = d_max_g / max_g;
    } else {
        A = d_min_g / max_g;
    }
    A = sqrt(max(0., A));
    A *= mix(-.125, -.2, muv.y);
    vec3 col_out = (col + colw * A) / (1.+4.*A);
    if (uv.x > (muv.x-1./vec2(adsk_result_w, adsk_result_h).x)) {
        if (uv.x > (muv.x+1./vec2(adsk_result_w, adsk_result_h).x)) {
            // 'Control' texture
            col_out = texture(channel1, uv).xyz;
        } else {
            // Black line
            col_out = vec3(0);
        }
    }
    
    // Output to screen
    gl_FragColor = vec4(col_out,1);
}

