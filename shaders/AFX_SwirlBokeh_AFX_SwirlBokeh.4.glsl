#version 430

// PASS 4: Zoom Blur
// Applies radial zoom blur from center using the same mask

layout( location = 0 ) out vec4 fragColor;

// System uniforms
layout( binding = 1 ) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
};

// User uniforms
layout( binding = 2 ) uniform UniformBlock
{
    bool mushOn;  // Enable lens mush (zoom blur)
    float mushStrength;  // Strength of the effect
    float mushSize;  // Same mask scale as radial blur
};

// Previous pass result (radial blur)
layout( binding = 5 ) uniform sampler2D adsk_results_pass3;

void main()
{
    vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec2 center = vec2(0.5, 0.5);
    
    // If lens mush is off, just pass through
    if (!mushOn || mushStrength < 0.01) {
        fragColor = texture(adsk_results_pass3, coords);
        return;
    }
    
    // Calculate distance from center
    vec2 delta = coords - center;
    float distanceFromCenter = length(delta);
    
    // Create a soft elliptical mask (same as radial blur)
    // Invert mushSize so larger values = larger effect area
    float invertedSize = 2.1 - mushSize;  // Maps 0.1-2.0 to 2.0-0.1
    float scaledDistance = distanceFromCenter / invertedSize;
    float radialMask = smoothstep(0.0, 1.0, scaledDistance);
    
    // Calculate blur strength based on mask
    float blurStrength = radialMask * mushStrength;
    
    // If blur strength is negligible, just pass through
    if (blurStrength < 0.01) {
        fragColor = texture(adsk_results_pass3, coords);
        return;
    }
    
    // Direction from center to current pixel (normalized)
    vec2 direction = normalize(delta);
    
    // Number of samples (more samples = smoother but slower)
    int numSamples = int(blurStrength * 15.0);
    numSamples = max(numSamples, 8);  // Minimum 8 samples
    numSamples = min(numSamples, 30); // Maximum 30 samples
    
    vec3 colorSum = vec3(0.0);
    float totalWeight = 0.0;
    
    // Sample along the line from center through current pixel
    for (int i = 0; i < numSamples; i++)
    {
        // Offset distance (zoom in/out from center)
        float t = float(i) / float(numSamples - 1);  // 0 to 1
        
        // Sample from closer to center to further out
        // Map t to range: (1 - blurStrength*0.05) to (1 + blurStrength*0.05)
        float zoomFactor = 1.0 + (t - 0.5) * blurStrength * 0.05;
        
        // Calculate sample position
        vec2 sampleDelta = delta * zoomFactor;
        vec2 sampleCoords = center + sampleDelta;
        
        // Gaussian-like weight (stronger in center)
        float weight = exp(-2.0 * (t - 0.5) * (t - 0.5));
        
        colorSum += texture(adsk_results_pass3, sampleCoords).rgb * weight;
        totalWeight += weight;
    }
    
    // Normalize
    vec3 blurredColor = colorSum / totalWeight;
    
    fragColor = vec4(blurredColor, 1.0);
}

