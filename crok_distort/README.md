# crok_distort

## Description

Adds a lens distortion effect. For all your glassy/watery/refrationy needs.

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
