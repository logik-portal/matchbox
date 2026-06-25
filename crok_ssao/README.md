# crok_ssao

## Description

This Matchbox shader simulates a SSAO look with just a Normal Map input.
Input:
- Front: RGB Beauty pass 
- Back: background
- Matte: matte
- Normal Map: normal map pass
Setup:
- Radius: radius of the ao effect
- Blur: apply a post blur to the AO pass
- Gamma: adjust the gamma of the AO only
Output:
- SSAO only: output just the AO pass not the comped image
- Alpha channel
Demo clip: http://vimeo.com/101860108
Based on: https://github.com/PlumCantaloupe/SSAO-Shader

## Flame Requirements

2015.0.0

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

ivar@inferno-op.com
