#version 430

// PASS 3: Lens Breathing
// Applies scaling based on blur amount to simulate lens breathing

layout( location = 0 ) out vec4 fragColor;

// System uniforms
layout( binding = 1 ) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
};

// User uniforms
layout( binding = 2 ) uniform UniformBlock
{
    bool breathingOn;     // Enable lens breathing
    float breathingX;     // X-axis breathing (0-1 maps to 100%-110%)
    float breathingY;     // Y-axis breathing (0-1 maps to 100%-110%)
    float blurAmount;     // Need blur amount to drive breathing effect
};

// Previous pass result (kernel blur)
layout( binding = 4 ) uniform sampler2D adsk_results_pass2;

void main()
{
    vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec2 center = vec2(0.5, 0.5);
    
    // If lens breathing is off, just pass through
    if (!breathingOn || (breathingX < 0.001 && breathingY < 0.001)) {
        fragColor = texture(adsk_results_pass2, coords);
        return;
    }
    
    // Calculate breathing scale based on blur amount
    // More blur = more breathing effect
    float blurFactor = blurAmount / 100.0; // Normalize blur amount (0-100 to 0-1)
    
    // Map UI values (0-1) to inverse scale (1.0-0.909)
    // breathingX/Y = 0 maps to 1.0 (100%), 1 maps to 0.909 (110% apparent size)
    float scaleX = 1.0 - (breathingX * 0.091 * blurFactor); // 1.0 - 0.091 = 0.909
    float scaleY = 1.0 - (breathingY * 0.091 * blurFactor); // 1.0 - 0.091 = 0.909
    
    // Apply scaling from center (inverse scaling to make image appear larger)
    vec2 delta = coords - center;
    vec2 scaledDelta = delta * vec2(scaleX, scaleY);
    vec2 scaledCoords = center + scaledDelta;
    
    // Clamp coordinates to prevent sampling outside texture bounds
    scaledCoords = clamp(scaledCoords, vec2(0.0), vec2(1.0));
    
    // Sample from scaled coordinates
    fragColor = texture(adsk_results_pass2, scaledCoords);
}