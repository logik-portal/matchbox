# kan_ExposureFix

## Description

Adjusts the exposure of the whole image so that the luminance of the selected pixels hits the target.
Can be used to remove in-camera exposure adjustments.
'Show measured luminance' enables a bar indicating the measured luminance.
If you're monitoring in HD then the x-coordinate of the end of the bar
is the value you'll want to enter in 'Target luminance' to get unaltered exposure on that frame.
I've written the shader for Baselight for Avid, but hope it'll work in Flame too... The shader expects linear input. Baselights converts automatically, for other hosts you might need to convert manually.
Demonstration: https://youtu.be/Vl4PXTvA8X8
Latest version at https://github.com/knejmann/kan_shaders.
For questions contact post@kan.dk

## Flame Requirements

2015.0.0

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author


