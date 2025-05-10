# Reframe

**Author:** Unknown

**Shader Type:** Matchbox

**Action:** Yes

**Timeline:** Yes

**Transition:** No

**Minimum Flame Version:** 


## Description
This Matchbox shader reframes a shot with respect to perspective distortion.

The concept of this shader is to simulate a different focal length alongside a different camera orientation (while maintaining the camera position).
Optionally the resulting image can be rotated via the Rotation field. By default, the resulting image will have the same horizontal orientation as the source.
The height of the photosensitive surface (image sensor, photograpic film, etc.) and the the relative lens aperture (in terms of brightness and bokeh) are conserved.
The resulting image format can be customized to any canvas resolution, the width of the virtual image will be matched proportional to the height (which will always be conserved) via the aspect ratio.
If the the image parameters are set to use a field of view angle rather than a focal length, the image height can be omitted. Note that the shader will still use the image height if the scaling mode is set to Focal Length.

The source image must be free of lens distortion for the process to function properly. Therefore this shader features a basic image rectification.

Additionally this shader provides the option of outputting (continuous) UV coordinates.

Adaptive Degradation is supported by this shader and will bypass antialiasing if enabled.

While this shader works quite well when downscaling (using antialiasing), its unsuited for upressing.
Note that this shader uses GL_NEAREST texture filtering, so that heavy aliasing might occur. This may require a high number of antialiasing samples (even 64 in extreme cases) to correct.

Warning: The matte (where present) is assumed to be of the same format as the source image. Otherwise the shader will produce incorrect results.

This shader is licensed under the terms of the MIT license.
