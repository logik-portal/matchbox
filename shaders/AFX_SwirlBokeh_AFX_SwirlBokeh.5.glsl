#version 430

// PASS 5: Vignette
// Darkens edges using radial mask

layout( location = 0 ) out vec4 fragColor;

// System uniforms
layout( binding = 1 ) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
};

// User uniforms
layout( binding = 2 ) uniform UniformBlock
{
    bool vignetteOn;
    float vignetteStrength;  // Darkening in stops (0 = no change, 1 = -1 stop, 2 = -2 stops)
    float vignetteSize;  // Size of vignette area
    float vignetteFalloff;  // Falloff curve power
};

// Previous pass result (zoom blur)
layout( binding = 6 ) uniform sampler2D adsk_results_pass4;

void main()
{
    vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec2 center = vec2(0.5, 0.5);
    
    // Get color from previous pass
    vec3 color = texture(adsk_results_pass4, coords).rgb;
    
    // If vignette is off, just pass through
    if (!vignetteOn || vignetteStrength < 0.01) {
        fragColor = vec4(color, 1.0);
        return;
    }
    
    // Calculate distance from center
    vec2 delta = coords - center;
    float distanceFromCenter = length(delta);
    
    // Create a soft elliptical mask (same approach as mush)
    // Invert vignetteSize so larger values = larger vignette area
    float invertedSize = 2.1 - vignetteSize;
    float scaledDistance = distanceFromCenter / invertedSize;
    
    // Smooth falloff using smoothstep for soft gradient
    // Clamp to ensure we get full 0-1 range
    float vignetteMask = smoothstep(0.0, 1.0, clamp(scaledDistance, 0.0, 1.0));
    
    // Apply falloff curve for non-linear gradient
    vignetteMask = pow(vignetteMask, vignetteFalloff);
    
    // Convert stops to multiply factor
    // 1 stop = 2x darker (multiply by 0.5)
    // 2 stops = 4x darker (multiply by 0.25)
    // Formula: multiply by 2^(-stops)
    float stopsToMultiplier = pow(2.0, -vignetteStrength);
    
    // Calculate darkening factor
    // At center (mask=0): factor = 1.0 (no darkening)
    // At edges (mask=1): factor = stopsToMultiplier (darkened by N stops)
    float darkenFactor = mix(1.0, stopsToMultiplier, vignetteMask);
    
    // Apply vignette
    vec3 vignetted = color * darkenFactor;
    
    fragColor = vec4(vignetted, 1.0);
}

