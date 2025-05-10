# Ls Shadowplate

**Author:** Lewis Saunders

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Experiment in removing direct sun from an image to make a completely shady plate for comping in new shadows, based on https://www.youtube.com/watch?v=Yb3Cn3JnkUI (the part from 5:25)

Super rapid demo: https://www.youtube.com/watch?v=LfNX3SdyqkQ

It converts to a perceptual colourspace to seperate brightness from colour, then pulls a key for the highlights and gains them down, repeating the process many times.  Then the colour channels are replaced from the original and optionally blurred

The matte output can help to set the key protect controls, and to grade further downstream.
