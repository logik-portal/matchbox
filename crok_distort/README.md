# crok_distort

## Description

This Matchbox shader adds a lens distortion effect.
Input:
- Front: source clip
- Lens: distortion clip
- Matte: region of interest
- Strength: strength clip
Setup:
- Amount: overall distortion
- Displace: the displacement amount
- Softness: amount of softness applied to the distortion
- Rotate: offset the distortion
Filtering:
- Blur Lens: softens incoming lens clip
- Blur Strength: softens incoming strength clip
- Strength Amount: blends in / out strength clip
- FXAA Amount: amount of Antialiasing applied
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
