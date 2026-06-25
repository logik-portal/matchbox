# crok_noise_wipe

## Description

This Matchbox shader creates a noise wipe / dissolve.
Setup:
- Noise: noise detail
- Amplitude: noise amplitude
- Softness: softness value for the wipe / dissolve area
- Rotation: direction of the wipe
- Scale: zoom in / out of the Noise
- Mix: amount of wipe applied to the images
- Dissolve: switch from wipe to dissolve
- Horizontal: switch from vertical to horizontal wipe
- Invert: invert the transition
Output:
- RGB Beauty pass
- Alpha channel
Demo clip: http://vimeo.com/100036530
Based on http://glsl.heroku.com/e#17891.7

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
