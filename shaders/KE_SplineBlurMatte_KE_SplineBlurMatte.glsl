// Created by Ted Stanley (KuleshovEffect) - May, 2025
// v1.0 

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;

void main( void )
{
	// Sample the input texture
	vec2 texCoord = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
    vec3 inputColor = texture2D(front,texCoord).rgb;
    
    // If the input matte pixel is pure white, output black; if it's black, output black; otherwise, output white
    float grayscaleValue = inputColor.r; // Since it's a black and white image, we only need to sample one channel (red)

    // Output the result
    if ((grayscaleValue == 1.0) || (grayscaleValue == 0.0)) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0); // Output black where matte is pure white or black
    } else {
        gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0); // Output white where matte is gray
    }
}