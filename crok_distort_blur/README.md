# crok_distort_blur

## Description

This Matchbox shader adds a blured lens distortion effect.
Input:
- Front: source clip
- Matte: region of interest
- Displace: distortion clip
- Strength: strength clip
Setup:
- Distortion: overall distortion
- Blur Distortion: softens the incoming displace matte
- Blur: amount of blur applied to the Matte to get the directional blur effect
- Samples: how many samples are used for the directional blur
AntiAliasing:
- Enable FXAA: enables AntiAliasing
Demo clip: https://vimeo.com/150475472
Big thx to lewis@lewissaunders.com for helping me out on some parts of the shader

## Flame Requirements

2015.0.0

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

ivar@inferno-op.com

Big thx to lewis@lewissaunders.com for helping me out on some parts of the shader
