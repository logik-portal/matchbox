# Ls_Stickon

## Description

Recursively warp an image by motion vectors, to stick it to something.  Make sure bit depth is 16-bit fp! Supply backward motion vectors to the vector input, i.e. the second output of Motion Analysis, or even better the backward channel from Nuke 9's VectorGenerator.  The front and matte inputs should normally be a still lined up on the Accumulate From frame.

Demo: https://www.youtube.com/watch?v=m27XZX7dtJU

## Flame Requirements

Not specified

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

Lewis Saunders
