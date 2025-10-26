#version 430

// PASS 1: Noise Generation
// Generates simplex noise pattern for water reflection distortion

layout( location = 0 ) out vec4 fragColor;

// System uniforms
layout( binding = 1 ) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
    float adsk_time;
};

// User uniforms
layout( binding = 2 ) uniform UniformBlock
{
    // Noise controls
    float noiseFrequency;      // 0.1 - 10.0, controls noise complexity
    float noiseAmplitude;       // 0.0 - 1.0, controls noise strength
    float noiseScaleX;         // 0.1 - 5.0, horizontal noise scale
    float noiseScaleY;         // 0.1 - 5.0, vertical noise scale
    float noiseEvolution;       // 0.0 - 1.0, controls time evolution speed
    float flowDirection;        // Direction of noise flow (0-360 degrees)
    float flowSpeed;            // 0.0 - 5.0, speed of directional flow
    float speedMultiplier;      // 0.0 - 5.0, global speed multiplier
    float globalScale;          // 0.1 - 5.0, multiplies scale X/Y only
    bool previewNoise;          // Toggle to preview noise pattern
    
    // Fractal noise controls
    int noiseOctaves;           // 1 - 8, number of octaves for fractal noise
    float noiseLacunarity;      // 1.0 - 4.0, frequency multiplier per octave
    float noiseGain;            // 0.1 - 1.0, amplitude multiplier per octave
    
    // Distortion controls
    float distortionStrength;   // 0.0 - 1.0, controls warping amount
    float distortionDamping;   // 0.0 - 10.0, controls edge damping
    
    // Dispersion controls
    float dispersionStrength;   // 0.0 - 2.0, strength of wavelength separation
    float dispersionAngle;     // 0.0 - 360.0, angle of dispersion
    bool enableDispersion;    // Toggle dispersion on/off
    
    // Padding for alignment
    float _padding;
};

// Input texture
layout( binding = 3 ) uniform sampler2D front;

// Constants
const float NOISE_OFFSET_Y = 100.0;        // Offset for Y noise to create different pattern
const float NOISE_NORMALIZE_SCALE = 0.5;   // Scale for noise normalization
const float NOISE_NORMALIZE_OFFSET = 0.5;  // Offset for noise normalization
const float NOISE_EVOLUTION_SCALE = 0.1;   // Scale factor for noise evolution (1/10th speed)
const float FLOW_SPEED_SCALE = 0.1;         // Scale factor for flow speed

// Simplex noise implementation
// Based on Stefan Gustavson's implementation
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
    return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v) {
    const vec2 C = vec2(1.0/6.0, 1.0/3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);

    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;

    // Permutations
    i = mod289(i);
    vec4 p = permute(permute(permute(
                i.z + vec4(0.0, i1.z, i2.z, 1.0))
            + i.y + vec4(0.0, i1.y, i2.y, 1.0))
            + i.x + vec4(0.0, i1.x, i2.x, 1.0));

    // Gradients
    float n_ = 0.142857142857; // 1.0/7.0
    vec3 ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);

    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);

    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww;

    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);

    // Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

// Fractal noise for more complex patterns
float fbm(vec3 p, int octaves, float lacunarity, float gain) {
    const float INITIAL_AMPLITUDE = 0.5;
    const float INITIAL_FREQUENCY = 1.0;
    
    float value = 0.0;
    float amplitude = INITIAL_AMPLITUDE;
    float frequency = INITIAL_FREQUENCY;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * snoise(p * frequency);
        amplitude *= gain;
        frequency *= lacunarity;
    }
    
    return value;
}


void main()
{
    vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    
    if (previewNoise) {
        // Preview mode: show noise pattern
        // Calculate flow offset from degrees
        float flowRadians = radians(flowDirection);
        vec2 flowDir = vec2(cos(flowRadians), sin(flowRadians));
        vec2 flowOffset = flowDir * (flowSpeed * speedMultiplier) * FLOW_SPEED_SCALE * adsk_time;
        
        // Apply flow to noise sampling position, not to the coordinate system
        vec2 noiseCoords = coords * noiseFrequency / (vec2(noiseScaleX, noiseScaleY) * globalScale) + flowOffset;
        vec3 noisePos = vec3(noiseCoords, adsk_time * (noiseEvolution * speedMultiplier) * NOISE_EVOLUTION_SCALE);
        float noise = fbm(noisePos, noiseOctaves, noiseLacunarity, noiseGain);
        
        // Normalize noise to 0-1 range
        noise = noise * NOISE_NORMALIZE_SCALE + NOISE_NORMALIZE_OFFSET;
        
        // Apply amplitude control
        noise = mix(0.5, noise, noiseAmplitude);
        
        fragColor = vec4(vec3(noise), 1.0);
    } else {
        // Apply distortion to the input image (always on)
            // Generate noise for X and Y distortion
            // Calculate flow offset from degrees
            float flowRadians = radians(flowDirection);
            vec2 flowDir = vec2(cos(flowRadians), sin(flowRadians));
            vec2 flowOffset = flowDir * (flowSpeed * speedMultiplier) * FLOW_SPEED_SCALE * adsk_time;
            
            // Apply flow to noise sampling position, not to the coordinate system
            vec2 noiseCoords = coords * noiseFrequency / (vec2(noiseScaleX, noiseScaleY) * globalScale) + flowOffset;
            vec3 noisePosX = vec3(noiseCoords, adsk_time * (noiseEvolution * speedMultiplier) * NOISE_EVOLUTION_SCALE);
            vec3 noisePosY = vec3(noiseCoords, adsk_time * (noiseEvolution * speedMultiplier) * NOISE_EVOLUTION_SCALE + NOISE_OFFSET_Y);
            
            float noiseX = fbm(noisePosX, noiseOctaves, noiseLacunarity, noiseGain);
            float noiseY = fbm(noisePosY, noiseOctaves, noiseLacunarity, noiseGain);
            
            // Normalize noise to 0-1 range
            noiseX = noiseX * NOISE_NORMALIZE_SCALE + NOISE_NORMALIZE_OFFSET;
            noiseY = noiseY * NOISE_NORMALIZE_SCALE + NOISE_NORMALIZE_OFFSET;
            
            // Convert back to -1 to 1 range
            noiseX = (noiseX - 0.5) * 2.0;
            noiseY = (noiseY - 0.5) * 2.0;
            
            // Apply amplitude control
            noiseX *= noiseAmplitude;
            noiseY *= noiseAmplitude;
            
            // Calculate edge dampening factor
            vec2 center = vec2(0.5, 0.5);
            vec2 distanceFromCenter = abs(coords - center);
            float maxDistance = max(distanceFromCenter.x, distanceFromCenter.y);
            float edgeDampening = pow(1.0 - maxDistance * 2.0, distortionDamping);
            edgeDampening = clamp(edgeDampening, 0.0, 1.0);
            
            // Apply distortion strength with edge dampening
            noiseX *= distortionStrength * edgeDampening;
            noiseY *= distortionStrength * edgeDampening;
            
            // Calculate distortion offset
            vec2 distortion = vec2(noiseX, noiseY);
            
            // Apply distortion to UV coordinates
            vec2 distortedCoords = coords + distortion;
            
            // Sample with distorted coordinates
            fragColor = texture(front, distortedCoords);
        
    }
}
