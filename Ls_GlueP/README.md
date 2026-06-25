# Ls_GlueP

## Description

Project an image onto a position pass, to glue it onto a CG render.  Demo video, including how to render the P pass: http://youtube.com/watch?v=YkgHAMwtmpw
Connect the front and optional matte images to project, and a world Position pass.  Then set up the position, rotation and FOV of the projection, usually by copying the values from an Action camera node at the frame you want to project on.  On that frame you should see your projection image as-is.  It should then be glued onto the CG for all other frames.
lewis@lewissaunders.com

## Flame Requirements

2015.0.0

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author


