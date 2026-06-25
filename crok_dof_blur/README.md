# crok_dof_blur

## Description

This Matchbox shader simulates depth of field with bokeh.
Version 3.1
Input:
- Front: source clip
- Depth Map: depth map
Setup:
- Amount : how much blur is applied
- Threshold : highlight threshold
- Gain : highlight gain
- Chromatic Abe. : highlight chromatic aberration 
- Dither : sample dithering amount
- Rings : ring amount
- Samples : how many samples are used for the bokeh
- Noise : use noise instead of pattern for sample dithering
- Pentagon Shape : use pentagon as bokeh shape
- Feather Shape : pentagon shape feather
- Range : focal range
- Focal Depth : focal depth, if you use an external matte
- Autofocus : use autofocus in shader
- Depth Map Blur : blurs the depth buffer
- Bias: bokeh edge bias
Demo clip: https://vimeo.com/82195519
Shader developer: martins upitis
Based on http://devlog-martinsh.blogspot.fr/2011/12/glsl-depth-of-field-with-bokeh-v23.html
This work is licensed under a Creative Commons Attribution 3.0 Unported License.
You are free to share, modify and adapt it for your needs, and even use it for commercial use.

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
