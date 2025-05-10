# KE GradTrack

**Author:** Ted Kuleshov

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 2017.0


## Description
Generates a gradient between two tracked points by continuously sampling the color underneath them.

Front input required, matte input optional.

Get tracking data from two axis nodes, then link those channels to the Tracking fields.
Use the Adjustments fields to dial in where the sample should come from.

-Sample Blur will average a larger area under the point.
-Bias will move the center of the gradient closer or further to the Start or End location.

There are three Output options:
    -UI Overlay will show where the samples are coming from, and the direction of the gradient.
    -Gradient will draw the full frame gradient.
    -Comp will put the gradient over the Front input, through a matte.

Matte output is a black-and-white version of the gradient, so each color could be adjusted downstream.

4-point gradients can be created differently by changing the Version drop down.

Updates:

    - Now with a four point gradient!
    - Added an Icon option to the Adjust field, so you can drag an axis icon in the UI. However, due to Matchbox limitations, the icon is disconnected from the point.
