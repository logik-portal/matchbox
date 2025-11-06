# nob_threshold

## Description

This Matchbox shader applies a threshold filter to an image.

If a threshold for luminance is applied, the blue channel weight is implicitly calculated for normalization.

Note that this shader does not perform any image scaling or reformatting, so the operation may be incorrect if the result image format does not match the input image format. It is recommended to leave the canvas resolution as <Same As Input 1>.

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
