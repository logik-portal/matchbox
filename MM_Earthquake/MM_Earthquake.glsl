// version 120 required for Mac OpenGL compatibility (Flame Matchbox)
#version 120

// Provided automatically by Flame
uniform float adsk_result_w, adsk_result_h;
uniform float adsk_time;

// Inputs
uniform sampler2D front;

// --- User controls ---
uniform bool  shakeEnabled;
uniform float shakeAmount;
uniform float shakeSpeed;
uniform bool  shakeX;
uniform bool  shakeY;
uniform bool  rotationEnabled;
uniform float rotationAmount;
uniform bool  motionBlurEnabled;
uniform float motionBlurShutter;  // exposure window as fraction of shake period (0-1)
uniform bool  flickerEnabled;
uniform float flickerAmount;
uniform float flickerSpeed;

#define PI          3.14159265
#define MB_SAMPLES  20

// ── Noise helpers ─────────────────────────────────────────────────────────────
float hash(float n)
{
    return fract(sin(n) * 43758.5453123);
}

float noise1(float t)
{
    float i = floor(t);
    float f = fract(t);
    float u = f * f * (3.0 - 2.0 * f);
    return mix(hash(i), hash(i + 1.0), u) * 2.0 - 1.0;
}

float fractalNoise(float t)
{
    return noise1(t)        * 0.5
         + noise1(t * 2.17) * 0.25
         + noise1(t * 4.73) * 0.125
         + noise1(t * 9.81) * 0.0625;
}

// Returns the displaced UV for a given time sample
vec2 shakenUV(vec2 baseUV, float t)
{
    vec2 uv = baseUV;

    float dx = shakeX ? fractalNoise(t + 0.0)  * shakeAmount : 0.0;
    float dy = shakeY ? fractalNoise(t + 17.3) * shakeAmount * (adsk_result_h / adsk_result_w) : 0.0;
    uv += vec2(dx, dy);

    if (rotationEnabled)
    {
        float angle = fractalNoise(t + 31.7) * rotationAmount * (PI / 180.0);
        float s = sin(angle);
        float c = cos(angle);
        vec2 centered = uv - 0.5;
        uv = vec2(c * centered.x - s * centered.y,
                  s * centered.x + c * centered.y) + 0.5;
    }

    return clamp(uv, 0.0, 1.0);
}

void main(void)
{
    vec2 res    = vec2(adsk_result_w, adsk_result_h);
    vec2 baseUV = gl_FragCoord.xy / res;

    vec4 col = vec4(0.0);

    if (shakeEnabled && motionBlurEnabled)
    {
        // Sample across the shutter window and accumulate
        float halfWindow = motionBlurShutter * 0.5 / shakeSpeed;

        for (int i = 0; i < MB_SAMPLES; i++)
        {
            float offset = (float(i) / float(MB_SAMPLES - 1) - 0.5) * 2.0 * halfWindow;
            float t      = adsk_time * shakeSpeed + offset;
            vec2 uv      = shakenUV(baseUV, t);
            col         += texture2D(front, uv);
        }
        col /= float(MB_SAMPLES);
    }
    else if (shakeEnabled)
    {
        float t = adsk_time * shakeSpeed;
        col     = texture2D(front, shakenUV(baseUV, t));
    }
    else
    {
        col = texture2D(front, baseUV);
    }

    // ── Brightness flicker ────────────────────────────────────────────────────
    if (flickerEnabled)
    {
        float frame      = floor(adsk_time * flickerSpeed);
        float brightness = 1.0 + (hash(frame + 99.1) - 0.5) * 2.0 * flickerAmount;
        col.rgb *= brightness;
    }

    gl_FragColor = col;
}
