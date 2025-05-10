# nob reframe

**Author:** Unknown

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 2024.1


## Description
This Matchbox shader reframes a shot with respect to perspective distortion.\n\nThe concept of this shader is to simulate a different focal length and camera orientation while maintaining the camera position.\nImage-wise only transformations are applied to acquire alternate view frames, thus brightness is retained and bokeh is transformed with the image (note that this can lead to deformed bokeh when extremely wide source FoV and strong off-centreing come together).\n\nThe Image Height parameter can be omitted if neither the source image nor the Scaling Mode is defined by the focal length.\n\nThe resulting image format can be customized to any canvas resolution, including but not limited to Flame Scaling Presets. Downscaling images to smaller formats while applying reframing, rectification and rotation at the same time is a particular strength of this shader, since it performs all operations at the same time. In contrast to a multi-node pipeline, this circumvents multiple introductions of softness or aliasing from intermediate image manipulations.\nNote that this shader uses GL_NEAREST texture filtering to conserve a maximum level of image detail, thus aliasing might be severe in certain cases if uncorrected. To counteract this, multisampling antialiasing can be activated, and the filter size enlarged (one may want to try to exhaust the number of samples first before using the Softness setting).\n\nSince the combined transformations per pixel are well-behaved over the resulting frame (for typical use), an intermediate pass containing the UV coordinates is calculated. The final pass transforming the image itself then uses those UVs, which is where the antialiasing is also applied (for performance reasons). Note that this can cause a loss of information for the very border pixels that would ideally interpolate from antialiasing sample locations outside the frame too.\nTo eliminate this error, one can specify a canvas resolution exactly 2 pixels wider and higher to then crop it back to the desired format using the Resize and Crop node.\nTake care to maintain correct pixel- and image aspect ratios between reframing and crop. Use the Force Result PAR selector if necessary.\n\nUpressing is best done with other means than this shader. Significant enlargements of small image viewports to a canvas of the same resolution as the input also might result in strong pixelation.\nIf need be, one can output the intermediate (continuous) UV coordinates and feed them into an external filter better suited towards upressing. Note that when outputting UV coordinates, the Matte result is intentionally black to incentivize running it too through the external filter.\n\nThe shader correctly handles conversions between all source and result formats, no matter the image- and pixel aspect ratios. In cases of deviating image aspect ratios, the width of the virtual result is matched according to the relative image height (which is retained from the source).\n\nAdaptive Degradation is supported by this shader, which conditionally bypasses antialiasing.
