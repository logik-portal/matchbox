# kan ExposureFix

**Author:** Ivar

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 2015.0.0


## Description
Adjusts the exposure of the whole image so that the luminance of the selected pixels hits the target.

Can be used to remove in-camera exposure adjustments.

Show measured luminance enables a bar indicating the measured luminance.
If youre monitoring in HD then the x-coordinate of the end of the bar
is the value youll want to enter in Target luminance to get unaltered exposure on that frame.

Ive written the shader for Baselight for Avid, but hope itll work in Flame too... The shader expects linear input. Baselights converts automatically, for other hosts you might need to convert manually.

Demonstration: https://youtu.be/Vl4PXTvA8X8
Latest version at https://github.com/knejmann/kan_shaders.
For questions contact post@kan.dk'
        
