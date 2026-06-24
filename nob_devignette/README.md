# nob_devignette

## Description

This Matchbox shader compensates for vignetting.
Up to four reference radii can be defined alongside individual gain compensation; optionally separate for red, green & blue colour channels. The vignetting centre is treated as an implicit fifth point with unchanged gain.
The shader calculates an even polynomial of eighth degree (in the radius from the vignetting centre) to interpolate those points.
Note that this shader does not perform any image scaling or reformatting, so the operation may be incorrect if the result image format does not match the input image format.
It is recommended to leave the [Output Resolution] as [Same As Input 1].
This shader is licensed under the terms of the MIT license.
For questions contact:
nobbl211@gmail.com

## Flame Requirements

2026.2.1

## Supported Modes

- ✅ **Action**: Supported
- ❌ **Transition**: Not supported
- ✅ **Timeline**: Supported

## Shader Type

Matchbox

## Author


