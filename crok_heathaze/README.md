# crok_heathaze

## Description

This Matchbox shader creates a heat haze effect.
Input:
- Front: source clip
- Matte: masken input
- Displace: external Displacement matte
- Strength: external Strength matte
Setup:
- Amount: strength of the distortion
- Smoothness: blur the incomming distortion matte (works on internal and external matte)
- Amount: strengt of applied hmotion blur
- Samples: motion blur samples
- Speed: speed of noise
- Detail: detail of the noise structure
- Direction: noise animation direction
- Use External Matte: use an external matte instead of the internal matte for the displacement
- Oversampling: number of pixel samples
- Softness: spacing between pixel samples
Demo clip: http://vimeo.com/115514251
Big thx to lewis@lewissaunders.com for help and code snippets

## Flame Requirements

2012.0.0

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

Ivar
