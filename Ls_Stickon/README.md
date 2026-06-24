# Ls_Stickon

## Description

Recursively warp an image 
Works in version 2017 only!
Demo: https://www.youtube.com/watch?v=m27XZX7dtJU
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

motion vectors, to stick it to something.  Make sure bit depth is 16-bit fp! Supply backward motion vectors to the vector input, i.e. the second output of Motion Analysis, or even better the backward channel from Nuke 9's VectorGenerator.  The front and matte inputs should normally be a still lined up on the Accumulate From frame.
