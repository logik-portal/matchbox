# nob_normalise

## Description

This Matchbox shader performs image luminance normalization.

All frames will be individually adjusted to match the same arithmetic mean exposure, optionally weighted via a supplied selective.
This is especially handy for removing flicker from a disturbed source, especially in combination with isolating a known static area of the image via selective.

Note that the source and target colour spaces are implied to be scene linear.

Note that this shader does not perform any image scaling or reformatting, so the operation may be incorrect if the result and input image formats don’t match.
It is recommended to leave the canvas resolution as <Same As Input 1>.

This shader is licensed under the terms of the MIT license.

## Flame Requirements

Not specified

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

nobbl211
