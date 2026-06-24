#version 120

// Flame required uniforms
uniform float adsk_result_w, adsk_result_h;
uniform float adsk_time;

// Artistic controls
uniform float cloud_scale;       // 0.4 - 3.0   (size of cloud formations)
uniform float cloud_density;     // 0.5 - 3.5   (overall thickness)
uniform float cloud_speed;       // 0.0 - 1.5
uniform vec3  sun_dir;           // Sun direction (will be normalized)
uniform float scattering;        // 0.5 - 2.5   (overall brightness of light in clouds)

// Quality / performance
uniform float quality;           // 0.5 - 2.0   (controls steps and light samples)
uniform float exposure;          // 0.8 - 2.0

// Camera positioning
uniform float camera_x;          // -20 to 20
uniform float camera_y;          // -20 to 20
uniform float camera_z;          // -30 to 5   (negative = further back)

// Background input
uniform sampler2D front;

// ================== HIGH QUALITY NOISE (Perlin + Worley for fluffiness) ==================

vec3 hash33(vec3 p) {
    p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.xxy + p.yxx) * p.zyx);
}

float perlin3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float n000 = dot(hash33(i) * 2.0 - 1.0, f);
    float n100 = dot(hash33(i + vec3(1,0,0)) * 2.0 - 1.0, f - vec3(1,0,0));
    float n010 = dot(hash33(i + vec3(0,1,0)) * 2.0 - 1.0, f - vec3(0,1,0));
    float n110 = dot(hash33(i + vec3(1,1,0)) * 2.0 - 1.0, f - vec3(1,1,0));
    float n001 = dot(hash33(i + vec3(0,0,1)) * 2.0 - 1.0, f - vec3(0,0,1));
    float n101 = dot(hash33(i + vec3(1,0,1)) * 2.0 - 1.0, f - vec3(1,0,1));
    float n011 = dot(hash33(i + vec3(0,1,1)) * 2.0 - 1.0, f - vec3(0,1,1));
    float n111 = dot(hash33(i + vec3(1,1,1)) * 2.0 - 1.0, f - vec3(1,1,1));

    return mix(
        mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
        mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
        f.z
    ) * 0.5 + 0.5;
}

float worley3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    float minDist = 1.0;

    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            for (int z = -1; z <= 1; z++) {
                vec3 neighbor = vec3(float(x), float(y), float(z));
                vec3 point = neighbor + hash33(i + neighbor) - f;
                minDist = min(minDist, length(point));
            }
        }
    }
    return minDist;
}

// This combination (Perlin + Worley) is excellent for fluffy, billowy clouds (inspired by iq and many modern cloud shaders)
float perlinWorley(vec3 p, float perlinWeight) {
    float pNoise = perlin3D(p);
    float wNoise = worley3D(p * 1.7);
    return mix(pNoise, 1.0 - wNoise, perlinWeight);
}

float fbmCloud(vec3 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.6;
    float frequency = 1.0;
    float maxValue = 0.0;

    for (int i = 0; i < octaves; i++) {
        // Mix of Perlin and Worley gives that nice fluffy, soft-yet-detailed look
        value += perlinWorley(p * frequency, 0.65) * amplitude;
        maxValue += amplitude;
        frequency *= 2.1;
        amplitude *= 0.5;
    }
    return value / maxValue;
}

// ================== DENSITY FUNCTION (with height shaping for fluffiness) ==================

float getCloudDensity(vec3 p, float time) {
    // Animate the volume
    vec3 wind = vec3(time * cloud_speed * 0.15, time * cloud_speed * 0.04, time * cloud_speed * 0.08);
    vec3 q = p + wind;

    // Main cloud shape using high-quality fbm
    float base = fbmCloud(q * cloud_scale, 6);

    // Add extra fine detail for that soft fluffy texture
    float detail = (perlin3D(q * cloud_scale * 7.5) - 0.5) * 0.25 * 1.2;

    float dens = base + detail;

    // Soft remapping for fluffy edges (very important for the look)
    dens = smoothstep(0.28, 0.72, dens);

    // Height shaping - makes clouds look more natural and less like a hard box
    float h = p.y * 0.8 + 0.5;   // simple height field
    float heightMask = smoothstep(0.0, 0.25, h) * smoothstep(1.3, 0.85, h);
    dens *= heightMask;

    // Overall density control
    dens *= cloud_density * 1.8;

    return max(0.0, dens);
}

// ================== LIGHT MARCHING (this is what makes clouds look truly volumetric and fluffy) ==================

float lightMarch(vec3 pos, vec3 sunDir, float time) {
    float transmittance = 1.0;
    float stepSize = 0.7;
    int samples = int(mix(3.0, 7.0, clamp(quality, 0.0, 1.0)));

    for (int i = 0; i < 8; i++) {
        if (i >= samples) break;
        pos += sunDir * stepSize;
        float d = getCloudDensity(pos, time);
        transmittance *= exp(-d * stepSize * 0.6);
        stepSize *= 1.15; // accelerate to reduce cost
    }
    return transmittance;
}

// ================== SCATTERING ==================

float HenyeyGreenstein(float g, float mu) {
    float gg = g * g;
    float denom = 1.0 + gg - 2.0 * g * mu;
    denom = max(denom, 0.0001);
    return (1.0 - gg) / (4.0 * 3.14159265 * pow(denom, 1.5));
}

// ================== MAIN ==================

void main(void) {
    vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec3 background = texture2D(front, uv).rgb;

    vec2 p = uv * 2.0 - 1.0;
    p.x *= adsk_result_w / adsk_result_h;

    vec3 ro = vec3(camera_x, camera_y, camera_z);
    vec3 rd = normalize(vec3(p, 1.0));

    vec3 sunDir = normalize(sun_dir);

    float t = 0.0;
    float transmittance = 1.0;
    vec3 scattered = vec3(0.0);

    // Quality-controlled stepping
    float stepSize = mix(0.14, 0.065, clamp(quality, 0.0, 1.6));
    int maxSteps = int(mix(48.0, 140.0, clamp(quality, 0.0, 1.8)));

    for (int i = 0; i < 160; i++) {
        if (i >= maxSteps) break;

        vec3 pos = ro + rd * t;

        float density = getCloudDensity(pos, adsk_time);

        if (density > 0.008) {
            // Real light marching for soft, fluffy lighting
            float light = lightMarch(pos, sunDir, adsk_time);

            // Proper scattering
            float mu = dot(rd, sunDir);
            float phase = HenyeyGreenstein(0.75, mu);   // nice forward scattering

            // Beautiful cloud color with light variation
            vec3 cloudCol = mix(vec3(0.52, 0.58, 0.68), vec3(1.0, 0.96, 0.85), light * 0.9 + 0.1);
            vec3 inScatter = cloudCol * phase * scattering * light;

            float absorb = density * stepSize * 0.95;
            transmittance *= exp(-absorb);

            scattered += inScatter * absorb * transmittance;

            if (transmittance < 0.015) break;
        }

        t += stepSize;
        if (t > 32.0) break;
    }

    // Final composite
    vec3 finalColor = background * transmittance + scattered;
    finalColor *= exposure;

    // Gentle filmic tonemapping for nice contrast
    finalColor = (finalColor * (2.51 * finalColor + 0.03)) / (finalColor * (2.43 * finalColor + 0.59) + 0.14);
    finalColor = pow(max(finalColor, 0.0), vec3(0.88));

    gl_FragColor = vec4(finalColor, 1.0);
}
