# crok_fast_grain

## Description

Simulates a film like grain.

Input:

    - Front: source clip

Setup:

    - Amount : how much grain is applied
    - Size : grain size
    - Coloured Grain : enables coloured grain
    - Colour : colour saturation of the grain
    - Luma : brightness of the grain

Updates:

    - Modified default input to be Front.

    - Fixed a half-pixel offset causing an image shift and interpolation softness + edge artifacts

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
