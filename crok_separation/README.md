# crok_separation

## Description

This Matchbox shader creates a low pass and high pass filter sometimes calles frequency separation
HINT: You need to combine both passes with a PS_LinearLight
Input:
- Front: source clip
Output:
- RGB: LowPass filter
- Matte: HighPass filter  
Setup:
- Blur: adjust the softness of the LowPass Filter
- Output HighPass as RGB: outputs the Higpass filter as an RGB image instead of a BW in the Matte output 
Demo clip: http://vimeo.com/111974170

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
