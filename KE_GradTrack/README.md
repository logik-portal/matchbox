# KE_GradTrack

## Description

Generates a gradient between two or four tracked points 
Front input required, matte input optional.
Get tracking data from Action axis nodes, then link those channels to the Tracking fields.
Use the Adjustments fields to dial in where the sample should come from.
•Sample Blur will average a larger area under the point.
•Bias will move the center of the gradient closer or further to the Start or End location.
(Bias only works for a 2-point gradient)
There are three Output options:
-UI Overlay will show where the samples are coming from, and the direction of the gradient.
-Gradient will draw the full frame gradient.
-Comp will put the gradient over the Front input, through a matte.
Matte output is a black-and-white version of the gradient, so each color could be adjusted downstream.
(Matte output only works for a 2-point gradient)
4-point gradients can be created differently 
Demo:
https://vimeo.com/953262222
Live Demo:
https://www.youtube.com/watch?v=O7nElwMPi48
Begins six minutes in.
Based on Ivar's crok_gradient: https://logik-matchbook.org/shader/crok_gradient

## Flame Requirements

2017.0.0

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

continuously sampling the color underneath them.
