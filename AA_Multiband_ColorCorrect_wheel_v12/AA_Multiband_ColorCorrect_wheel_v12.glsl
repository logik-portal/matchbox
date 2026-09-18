// AA_Multiband_ColorCorrect_wheel_v12.glsl
// Matchbox-style multiband colour corrector
//
// HOW IT WORKS
// - Master affects the full image. Low / Low Mid / Mid / High Mid / High are fixed luminance bands.
// - Each tab has Gamma, Gain, Offset, Exposure, Contrast and Saturation controls.
// - Colour Wheel: Hue chooses the target hue, Gain controls how strongly that hue is added, and Mix scales the wheel contribution.
//   The wheel can colour neutral pixels as well as shift existing colour.
// - Use Picker restricts that tab to the selected colour. Picker Tol widens/narrows the selection and Picker Soft feathers its edge.
// - Show Matte previews the active selection in white. On tonal tabs this is: tonal band * picker (when enabled) * external Matte.
// - Optional external Matte limits every correction and matte preview: white = full effect, black = protected, gray = partial effect.
// - Bypass disables all corrections on the current tab.
//
// Version: AA_Multiband_ColorCorrect_wheel_v12
// Made by Anthony Augusta / AnthonyAugustaCreations@gmail.com

uniform sampler2D front;
uniform sampler2D matte;
uniform float adsk_result_w;
uniform float adsk_result_h;
uniform bool master_show_matte;
uniform bool master_bypass;
uniform bool master_picker_enable;
uniform vec3 master_picker_color;
uniform float master_picker_tolerance;
uniform float master_picker_softness;
uniform float master_exposure;
uniform float master_contrast;
uniform float master_saturation;
uniform float master_curve_control;
uniform float master_gain;
uniform vec3 masterColourWheel;
uniform float master_offset;
uniform bool low_show_matte;
uniform bool low_bypass;
uniform bool low_picker_enable;
uniform vec3 low_picker_color;
uniform float low_picker_tolerance;
uniform float low_picker_softness;
uniform float low_exposure;
uniform float low_contrast;
uniform float low_saturation;
uniform float low_curve_control;
uniform float low_gain;
uniform vec3 lowColourWheel;
uniform float low_offset;
uniform bool low_mid_show_matte;
uniform bool low_mid_bypass;
uniform bool low_mid_picker_enable;
uniform vec3 low_mid_picker_color;
uniform float low_mid_picker_tolerance;
uniform float low_mid_picker_softness;
uniform float low_mid_exposure;
uniform float low_mid_contrast;
uniform float low_mid_saturation;
uniform float low_mid_curve_control;
uniform float low_mid_gain;
uniform vec3 lowMidColourWheel;
uniform float low_mid_offset;
uniform bool mid_show_matte;
uniform bool mid_bypass;
uniform bool mid_picker_enable;
uniform vec3 mid_picker_color;
uniform float mid_picker_tolerance;
uniform float mid_picker_softness;
uniform float mid_exposure;
uniform float mid_contrast;
uniform float mid_saturation;
uniform float mid_curve_control;
uniform float mid_gain;
uniform vec3 midColourWheel;
uniform float mid_offset;
uniform bool high_mid_show_matte;
uniform bool high_mid_bypass;
uniform bool high_mid_picker_enable;
uniform vec3 high_mid_picker_color;
uniform float high_mid_picker_tolerance;
uniform float high_mid_picker_softness;
uniform float high_mid_exposure;
uniform float high_mid_contrast;
uniform float high_mid_saturation;
uniform float high_mid_curve_control;
uniform float high_mid_gain;
uniform vec3 highMidColourWheel;
uniform float high_mid_offset;
uniform bool high_show_matte;
uniform bool high_bypass;
uniform bool high_picker_enable;
uniform vec3 high_picker_color;
uniform float high_picker_tolerance;
uniform float high_picker_softness;
uniform float high_exposure;
uniform float high_contrast;
uniform float high_saturation;
uniform float high_curve_control;
uniform float high_gain;
uniform vec3 highColourWheel;
uniform float high_offset;

float luminance(vec3 c)
{
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float bandPass(float y, float lowEdge, float lowFull, float highFull, float highEdge)
{
    // Soft fixed tonal band. The center of the band is full strength,
    // then fades out at the neighboring band edges.
    float rise = smoothstep(lowEdge, lowFull, y);
    float fall = 1.0 - smoothstep(highFull, highEdge, y);
    return clamp(rise * fall, 0.0, 1.0);
}

float lowBandMask(float y)
{
    return 1.0 - smoothstep(0.18, 0.34, y);
}

float lowMidBandMask(float y)
{
    return bandPass(y, 0.16, 0.28, 0.36, 0.50);
}

float midBandMask(float y)
{
    return bandPass(y, 0.34, 0.46, 0.54, 0.66);
}

float highMidBandMask(float y)
{
    return bandPass(y, 0.50, 0.64, 0.72, 0.84);
}

float highBandMask(float y)
{
    return smoothstep(0.66, 0.82, y);
}

vec3 safeNormalizeColor(vec3 c)
{
    float m = max(max(c.r, c.g), max(c.b, 0.0001));
    return c / m;
}


float externalMatteMask(vec2 uv)
{
    // Optional external matte input.
    // Use RGB luminance for normal matte images. If an alpha-only matte is supplied
    // with black RGB and non-opaque alpha, fall back to alpha.
    vec4 m = texture2D(matte, uv);
    float rgbMatte = luminance(m.rgb);
    float alphaMatte = (rgbMatte < 0.0001 && m.a < 0.999) ? m.a : 0.0;
    return clamp(max(rgbMatte, alphaMatte), 0.0, 1.0);
}

float colorPickerMask(vec3 src, vec3 pick, float tolerance, float softness)
{
    // Picker/matte function only.
    vec3 a = safeNormalizeColor(max(src, vec3(0.0)));
    vec3 b = safeNormalizeColor(max(pick, vec3(0.0)));
    float dist = distance(a, b) / 1.7320508;
    float tol = max(tolerance, 0.0001);
    float soft = max(softness, 0.0001);
    return 1.0 - smoothstep(tol, tol + soft, dist);
}

float rgbHue01(vec3 c)
{
    vec3 col = max(c, vec3(0.0));
    float mx = max(max(col.r, col.g), col.b);
    float mn = min(min(col.r, col.g), col.b);
    float d = mx - mn;
    if (d < 0.00001) return 0.0;
    float h = 0.0;
    if (mx == col.r) {
        h = mod((col.g - col.b) / d, 6.0);
    } else if (mx == col.g) {
        h = ((col.b - col.r) / d) + 2.0;
    } else {
        h = ((col.r - col.g) / d) + 4.0;
    }
    return fract(h / 6.0);
}

float hueDistance01(float a, float b)
{
    float d = abs(fract(a) - fract(b));
    return min(d, 1.0 - d);
}


vec3 applySaturation(vec3 c, float sat)
{
    float luma = luminance(c);
    return mix(vec3(luma), c, sat);
}

vec3 applyContrast(vec3 c, float con)
{
    return (c - 0.5) * con + 0.5;
}

vec3 rgbToHsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsvToRgb(vec3 c)
{
    vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec3 applyHueCenter(vec3 c, float hueCenterDegrees, float hueGainPercent)
{
    // Hue is the selected output hue / target colour in degrees.
    // Hue Gain controls how strongly that target hue is applied.
    // Important: neutral pixels such as white, gray, and black have no original hue.
    // The wheel therefore adds target-hue saturation instead of only rotating existing chroma.
    // This lets a white image become any wheel colour, matching the expected Autodesk wheel behavior.
    vec3 base = max(c, vec3(0.0));
    vec3 hsv = rgbToHsv(base);
    float targetHue = fract(mod(hueCenterDegrees, 360.0) / 360.0);
    float strength = clamp(hueGainPercent / 100.0, 0.0, 1.0);

    float targetSaturation = clamp(max(hsv.y, strength), 0.0, 1.0);
    vec3 targetColor = hsvToRgb(vec3(targetHue, targetSaturation, hsv.z));
    return mix(base, targetColor, strength);
}

vec3 correctedColorNoHue(vec3 c, float exposure, float contrast, float saturation, float gamma, float gain, float offset)
{
    vec3 outc = c;
    outc *= pow(2.0, exposure);
    outc = max(outc, vec3(0.0));
    outc = pow(outc, vec3(1.0 / max(gamma, 0.0001)));
    outc *= gain;
    outc += vec3(offset);
    outc = applyContrast(outc, contrast);
    outc = applySaturation(outc, saturation);
    return outc;
}

vec3 applyBandCorrection(vec3 c, float baseMaskAmount, float hueMaskAmount, float exposure, float contrast, float saturation, float gamma, float gain, vec3 colourWheel, float offset)
{
    // Base correction controls are limited by the normal band/picker mask.
    // Colour Wheel correction uses its own hue path, but is still limited by the final tab selection mask.
    // The wheel does not create or modify the picker matte; it only uses the already-computed mask as a limiter.
    vec3 baseTarget = correctedColorNoHue(c, exposure, contrast, saturation, gamma, gain, offset);
    vec3 outc = mix(c, baseTarget, clamp(baseMaskAmount, 0.0, 1.0));

    // Colour Wheel widget values: x = Hue angle, y = Gain, z = Mix.
    float hueMask = clamp(hueMaskAmount, 0.0, 1.0);
    // Gain defaults to 0.0, so the widget is no-op until raised.
    float colourWheelHue = colourWheel.x;
    float colourWheelGain = max(colourWheel.y, 0.0);
    float colourWheelMix = clamp(colourWheel.z / 100.0, 0.0, 1.0);
    vec3 colourWheelTarget = applyHueCenter(outc, colourWheelHue, colourWheelGain * colourWheelMix);
    return mix(outc, colourWheelTarget, hueMask);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec4 src = texture2D(front, uv);

    float y = luminance(src.rgb);
    float matteInputMask = externalMatteMask(uv);
    float masterSelectionMask = 0.0;
    float visibleMatte = 0.0;

    // Picker/matte is evaluated only when Use Picker is on.
    // Pick Color/Tol/Soft limit the standard correction and matte preview only.
    // Colour Wheel Hue is independent from the picker calculation.
    // If Use Picker is enabled, the already-computed picker matte limits the wheel effect.
    // The wheel does not feed back into, expand, or help create the picker selection.
    float masterPickerMask = 1.0;
    float masterPickerMatte = 0.0;
    if (master_picker_enable) {
        masterPickerMatte = colorPickerMask(src.rgb, master_picker_color, master_picker_tolerance, master_picker_softness);
        masterPickerMask = masterPickerMatte;
    }

    float masterMask = masterPickerMask * matteInputMask;
    float masterAmt = master_bypass ? 0.0 : clamp(masterMask, 0.0, 1.0);
    float masterHueAmt = masterAmt;
    vec3 corrected = applyBandCorrection(src.rgb, masterAmt, masterHueAmt, master_exposure, master_contrast, master_saturation, master_curve_control, master_gain, masterColourWheel, master_offset);

    {
        float lowPickerMask = 1.0;
        float lowPickerMatte = 0.0;
        if (low_picker_enable) {
            lowPickerMatte = colorPickerMask(src.rgb, low_picker_color, low_picker_tolerance, low_picker_softness);
            lowPickerMask = lowPickerMatte;
        }
        float lowBand = lowBandMask(y);
        float lowMask = lowBand * lowPickerMask * matteInputMask;
        float lowAmt = low_bypass ? 0.0 : clamp(lowMask, 0.0, 1.0);
        float lowHueAmt = lowAmt;
        masterSelectionMask = max(masterSelectionMask, lowAmt);
        if (!low_bypass && low_show_matte) visibleMatte = max(visibleMatte, lowAmt);
        corrected = applyBandCorrection(corrected, lowAmt, lowHueAmt, low_exposure, low_contrast, low_saturation, low_curve_control, low_gain, lowColourWheel, low_offset);
    }

    {
        float low_midPickerMask = 1.0;
        float low_midPickerMatte = 0.0;
        if (low_mid_picker_enable) {
            low_midPickerMatte = colorPickerMask(src.rgb, low_mid_picker_color, low_mid_picker_tolerance, low_mid_picker_softness);
            low_midPickerMask = low_midPickerMatte;
        }
        float low_midBand = lowMidBandMask(y);
        float low_midMask = low_midBand * low_midPickerMask * matteInputMask;
        float low_midAmt = low_mid_bypass ? 0.0 : clamp(low_midMask, 0.0, 1.0);
        float low_midHueAmt = low_midAmt;
        masterSelectionMask = max(masterSelectionMask, low_midAmt);
        if (!low_mid_bypass && low_mid_show_matte) visibleMatte = max(visibleMatte, low_midAmt);
        corrected = applyBandCorrection(corrected, low_midAmt, low_midHueAmt, low_mid_exposure, low_mid_contrast, low_mid_saturation, low_mid_curve_control, low_mid_gain, lowMidColourWheel, low_mid_offset);
    }

    {
        float midPickerMask = 1.0;
        float midPickerMatte = 0.0;
        if (mid_picker_enable) {
            midPickerMatte = colorPickerMask(src.rgb, mid_picker_color, mid_picker_tolerance, mid_picker_softness);
            midPickerMask = midPickerMatte;
        }
        float midBand = midBandMask(y);
        float midMask = midBand * midPickerMask * matteInputMask;
        float midAmt = mid_bypass ? 0.0 : clamp(midMask, 0.0, 1.0);
        float midHueAmt = midAmt;
        masterSelectionMask = max(masterSelectionMask, midAmt);
        if (!mid_bypass && mid_show_matte) visibleMatte = max(visibleMatte, midAmt);
        corrected = applyBandCorrection(corrected, midAmt, midHueAmt, mid_exposure, mid_contrast, mid_saturation, mid_curve_control, mid_gain, midColourWheel, mid_offset);
    }

    {
        float high_midPickerMask = 1.0;
        float high_midPickerMatte = 0.0;
        if (high_mid_picker_enable) {
            high_midPickerMatte = colorPickerMask(src.rgb, high_mid_picker_color, high_mid_picker_tolerance, high_mid_picker_softness);
            high_midPickerMask = high_midPickerMatte;
        }
        float high_midBand = highMidBandMask(y);
        float high_midMask = high_midBand * high_midPickerMask * matteInputMask;
        float high_midAmt = high_mid_bypass ? 0.0 : clamp(high_midMask, 0.0, 1.0);
        float high_midHueAmt = high_midAmt;
        masterSelectionMask = max(masterSelectionMask, high_midAmt);
        if (!high_mid_bypass && high_mid_show_matte) visibleMatte = max(visibleMatte, high_midAmt);
        corrected = applyBandCorrection(corrected, high_midAmt, high_midHueAmt, high_mid_exposure, high_mid_contrast, high_mid_saturation, high_mid_curve_control, high_mid_gain, highMidColourWheel, high_mid_offset);
    }

    {
        float highPickerMask = 1.0;
        float highPickerMatte = 0.0;
        if (high_picker_enable) {
            highPickerMatte = colorPickerMask(src.rgb, high_picker_color, high_picker_tolerance, high_picker_softness);
            highPickerMask = highPickerMatte;
        }
        float highBand = highBandMask(y);
        float highMask = highBand * highPickerMask * matteInputMask;
        float highAmt = high_bypass ? 0.0 : clamp(highMask, 0.0, 1.0);
        float highHueAmt = highAmt;
        masterSelectionMask = max(masterSelectionMask, highAmt);
        if (!high_bypass && high_show_matte) visibleMatte = max(visibleMatte, highAmt);
        corrected = applyBandCorrection(corrected, highAmt, highHueAmt, high_exposure, high_contrast, high_saturation, high_curve_control, high_gain, highColourWheel, high_offset);
    }

    if (!master_bypass && master_show_matte) {
        // Master matte reflects the master colour picker multiplied by external Matte.
        // If Use Picker is off, Master Show Matte shows the external Matte input.
        // Tonal tabs show their channel/frequency band mattes, also multiplied by external Matte.
        float masterPreviewMatte = master_picker_enable ? (masterPickerMatte * matteInputMask) : matteInputMask;
        visibleMatte = max(visibleMatte, masterPreviewMatte);
    }

    bool anyShowMatte = (!master_bypass && master_show_matte) || (!low_bypass && low_show_matte) || (!low_mid_bypass && low_mid_show_matte) || (!mid_bypass && mid_show_matte) || (!high_mid_bypass && high_mid_show_matte) || (!high_bypass && high_show_matte);

    if (anyShowMatte) {
        // Matte preview: white = selected, black = protected.
        // Matte preview on Low / Low Mid / Mid / High Mid / High shows the fixed tonal channel/frequency band, multiplied by picker matte when Use Picker is enabled, and by the external Matte input.
        gl_FragColor = vec4(vec3(clamp(visibleMatte, 0.0, 1.0)), src.a);
    } else {
        gl_FragColor = vec4(corrected, src.a);
    }
}
