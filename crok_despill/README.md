# crok_despill

## Description

This Matchbox shader combines multiple LogicOps to streamline your keying batch schematic.
Input:
- Front: greenscreen clips
- Back: background clip
- Matte: keyed FG matte
- Despilled Front: despilled FG clip
Setup:
- 2D Histogram: adjust max and min input values of the despilled FG
Demo clip: http://vimeo.com/118993192
Based on this idea: 
http://forums.autodesk.com/t5/general-discussion/advanced-keying-spill-suppression/td-p/4270497
Video showing the general idea for Smoke and Nuke:
https://vimeo.com/62523139

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
