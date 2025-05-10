# cb rec709Check

**Author:** CB

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 2017.0


## Description
Validates Rec709 color and luma values with waveform overlay.

front - Input image
lumaThreshold - Sensitivity for illegal luma detection
chromaThreshold - Sensitivity for illegal chroma detection
highlightStrength - Strength of illegal value highlighting
showWaveform - Toggle waveform display
waveformHeight - Height of waveform overlay
waveformOpacity - Opacity of waveform overlay
resolution - Image resolution (width, height)

Illegal Rec709 Value Calculation:
Conversion: RGB to YCbCr using Rec709 coefficients (Y = luma, Cb/Cr = chroma).
Legal Ranges: Luma: 16/255 to 235/255; Chroma: 16/255 to 240/255.
Check: Illegal if Y, Cb, or Cr exceeds range ± threshold.
Intensity: Measures violation distance beyond range, scaled by threshold, clamped 0-1.
Visualization: Red for luma, green for chroma, yellow for both; waveform shows luma with illegal in red.

Check rec709 illegal values.
