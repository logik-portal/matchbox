# crok_separation

## Description

Creates a low pass and high pass filter sometimes calles frequency separation

HINT: You need to combine both passes with a PS_LinearLight

Input:

    - Front: source clip

Output:

    - RGB: LowPass filter
    - Matte: HighPass filter

Setup:

    - Blur: adjust the softness of the LowPass Filter
    - Output HighPass as RGB: outputs the Higpass filter as an RGB image instead of a BW in the Matte output

## Flame Requirements

Not specified

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

Ivar Beer
