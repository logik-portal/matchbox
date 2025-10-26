#version 430

// PASS 3: Radial Blur
// Applies spin blur based on distance from center

layout( location = 0 ) out vec4 fragColor;

// System uniforms
layout( binding = 1 ) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
};

// User uniforms
layout( binding = 2 ) uniform UniformBlock
{
    bool mushOn;  // Enable lens mush (radial blur)
    float mushStrength;  // Strength of the effect
    float mushSize;  // Scale of the radial mask (smaller = stronger at edges)
};

// Previous pass result (kernel blur)
layout( binding = 4 ) uniform sampler2D adsk_results_pass2;

const float PI = 3.14159265359;

void main()
{
    vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec2 center = vec2(0.5, 0.5);
    
    // If lens mush is off, just pass through
    if (!mushOn || mushStrength < 0.01) {
        fragColor = texture(adsk_results_pass2, coords);
        return;
    }
    
    // Calculate distance from center
    vec2 delta = coords - center;
    float distanceFromCenter = length(delta);
    
    // Create a soft elliptical mask
    // Invert mushSize so larger values = larger effect area
    float invertedSize = 2.1 - mushSize;  // Maps 0.1-2.0 to 2.0-0.1
    float scaledDistance = distanceFromCenter / invertedSize;
    
    // Smooth falloff using smoothstep for soft gradient
    float radialMask = smoothstep(0.0, 1.0, scaledDistance);
    
    // Calculate blur strength based on mask
    float blurStrength = radialMask * mushStrength;
    
    // If blur strength is negligible, just pass through
    if (blurStrength < 0.01) {
        fragColor = texture(adsk_results_pass2, coords);
        return;
    }
    
    // Calculate angle from center
    float angle = atan(delta.y, delta.x);
    
    // Number of samples (more samples = smoother but slower)
    int numSamples = int(blurStrength * 20.0);
    numSamples = max(numSamples, 8);  // Minimum 8 samples
    numSamples = min(numSamples, 40); // Maximum 40 samples
    
    // Total angle to sample across (in radians)
    float totalAngleSpread = blurStrength * 0.1;  // Adjust for intensity
    
    vec3 colorSum = vec3(0.0);
    float totalWeight = 0.0;
    
    // Sample along the circular arc
    for (int i = 0; i < numSamples; i++)
    {
        // Offset angle from -totalAngleSpread/2 to +totalAngleSpread/2
        float t = float(i) / float(numSamples - 1);  // 0 to 1
        float angleOffset = (t - 0.5) * totalAngleSpread;
        float sampleAngle = angle + angleOffset;
        
        // Calculate sample position on the circle
        vec2 sampleOffset = vec2(cos(sampleAngle), sin(sampleAngle)) * distanceFromCenter;
        vec2 sampleCoords = center + sampleOffset;
        
        // Gaussian-like weight (stronger in center)
        float weight = exp(-2.0 * (t - 0.5) * (t - 0.5));
        
        colorSum += texture(adsk_results_pass2, sampleCoords).rgb * weight;
        totalWeight += weight;
    }
    
    // Normalize
    vec3 blurredColor = colorSum / totalWeight;
    
    fragColor = vec4(blurredColor, 1.0);
}

