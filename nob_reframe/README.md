# nob_reframe

## Description

This Matchbox shader reframes a shot with respect to perspective distortion.
The concept of this shader is to simulate a different focal length and camera orientation while maintaining the camera's position.
Image-wise only spatial transformations are applied to acquire this alternate view, thus brightness is retained and bokeh is transformed with the image (note that this can lead to deformed bokeh when extremely wide source FoV and strong off-centreing come together).
The input [Image Parameters], namely [Image Height], [Focal Length] and [Field of View] are all in relation to the undistorted source, including potential (black) padded areas. Thus, depending on the frame of reference, the equivalent [Image Height] and [Field of View] might be larger, or the [Focal Length] smaller than what the visible portion is comprised of.
The [Image Height] parameter can be omitted if [Use Field of View] is enabled, and [Scaling Mode] is not [Focal Length].
The resulting image format can be customized to any canvas resolution as well as frame and pixel aspect ratios. In cases of different frame aspect ratios, the content is automatically scaled to fit the resulting frame height. Downscaling images to smaller formats while applying reframing, rectification and rotation at the same time is a particular strength of this shader, since it applies all operations simultaneously. In contrast to a multi-node pipeline, this circumvents generational loss due to multiple introductions of softness and/or aliasing in the individual steps.
Filtering is done through either a Box- or a Gauss-Kernel. The former - in combination with the default [sigma] of 0.289… (corresponding to a width of 1) ideal for retaining perfect sharpness; whereas the latter is better suited towards soft filtering, preventing not only aliasing but also temporal flickering (which might occur for the highest spatial-frequency sources & strong non-integer-ratio downsampling) - [sigma] values around 0.4 should be a decent starting point.
In either case, the number of samples should be set high enough to accommodate for a smooth filtering. In the case of Gauss filtering with a [sigma] larger than 0.5, even as high as 4096.
In lens-distortion rectification (un-distortion) and re-distortion workflows, the order of operations matters. Logically, the image is first rectified, then perspectively transformed, and lastly re-distorted (albeit internally, for creating the ST map, those operations are ordered reversed & individually performed inverted). The transformation itself is only correct for undistorted images, hence the rectification module in this shader. Do not attempt to correct existing distortion using the re-distortion settings and parameters, as this would result in incorrect perspective transformations nonetheless, due to improper order of operations.
Optionally, a external ST maps can be used for rectification and re-distortion, compatible with those generated 
If using a rectification map, shader adopts this map's format as the input format instead of Front's.
On the other hand, Re-distortion maps are implicitly expected to be of equal format as the output.
For enhanced performance, this shader internally uses an ST map representing the aggregate transformation which itself is bilinearly filtered; the nature of which is well behaved for typical use, resulting in negligible interpolation errors. Supersampling then takes place during the application of this ST map.
Note that this may cause a loss of information for border pixels, which would interpolate from sample locations outside the target-frame.
To eliminate this error, one can specify a higher & wider [Output Resolution], accommodating the filtering kernel size; to then crop the output to the desired format using the Resize & Crop node.
Take care to maintain correct pixel- & frame aspect ratios between reframing & crop. Use the [Force Result PAR] selector if necessary (for certain versions of Flame, the frame aspect ratio can snap to close-but-not-exact presets such as 16:9).
This shader, however, does not convert between Colour Spaces, thus when changing to a user defined [Output Resolution], make sure to use the Front's colour space tag; of for ST Map output, optionally use a data space tag.
Upressing is best done with other means than this shader. Significant enlargements of image portions for equal in- and output resolution might also result in strong pixelation.
For this, one can output the intermediate ST map and feed it into an external filter better suited towards upressing. Note that when outputting an ST map, the Matte output is then intentionally left black to incentivize running it too through external filtering.
Adaptive Degradation is supported 
This shader is licensed under the terms of the MIT license.
For questions contact:
nobbl211@gmail.com

## Flame Requirements

2027.0.0

## Supported Modes

- ✅ **Action**: Supported
- ❌ **Transition**: Not supported
- ✅ **Timeline**: Supported

## Shader Type

Matchbox

## Author

default, antialiasing is disabled for performance reasons, though it is strongly encouraged to enable it for final output.
