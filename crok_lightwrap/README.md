# crok_lightwrap

## Description

This Matchbox shader applies a lightwrap to the image.
Input:
- Comp: composed FG + BG without LightWrap
- Back: BG only
- Matte: FG matte
Setup:
- Logic Op: blend mode applied
- Size: amount of lightwrap
- Blend: blend in / out lightwrap
- Blur BG: amount of blur applied to the incomming BG plate
- Gain: adjust gain of the lighwrap matte
- Threshold: adjust lightwrap matte threshold
- Gain: adjust gain of the edge matte
- Threshold: adjust edge matte threshold
- Size: size of the edge blur
- Blur: blur the generated edge matte
- Blur Amount: amount of edgeblur applied
- Grain Amount: amount of grain applied
- Output: Comp / Lightwrap
Demo clip: http://vimeo.com/107401261

## Flame Requirements

2015.0.0

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

Ivar
