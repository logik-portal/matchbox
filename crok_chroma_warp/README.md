# crok_chroma_warp

## Description

This Matchbox shader creates chromatic aberrations and a barrel distortion.
Version: 1.9
Input:
- Front: source clip
- Chromatic Aberration Strength: Chromatic Aberration Strength matte
- Distortion Strength: Distortion Strength matte
Output:
- Result: result clip
- Matte: alpha channel
Setup:
- Amount: blur amount
- Iterations: number of steps to create the blur
- Saturation: Blend in/out the chroma offset
- Center: center of the effect
- Add Distortion: enable additional distortion
- Amount: amount of applied distortion
Based on: https://www.shadertoy.com/view/XssGz8
To the extent possible under law, the author has waived all copyright and related or neighboring rights to this work.
Demo clip: http://vimeo.com/89781715

## Flame Requirements

2015.0.0

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

Ivar
