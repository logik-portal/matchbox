# crok_distort_blur

## Description

Adds a blured lens distortion effect.

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

## Flame Requirements

Not specified

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

Ivar Beer and Lewis Saunders
