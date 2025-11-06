# nob_chromatic_adaptation

## Description

This Matchbox shader performs a chromatic adaptation.

It also takes care of primary colour space conversions, assuming that the source- and target colour spaces are scene linear.

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
