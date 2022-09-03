# The Artist
Processing version of After Dark 3.0 "The Artist" module
![Sample output](https://repository-images.githubusercontent.com/532388557/dd3becb5-65fb-4065-af6b-8bb5aef6c104)

## About
This is a Processing recreation of the After Dark 3.0 module "The Artist".  The screensaver takes an input image, then uses primitive shapes (circles or lines) to redraw it in increasing detail.  The result is a somewhat impressionistic rendering of the input.

The order of pixels drawn is determined by some form of edge-detection algorithm: areas of low detail are drawn first in large swatches.  Finely detailed areas are drawn later and with a smaller brush.

Here is a video of the original module in action:

https://youtu.be/kO0UFQP7hcs

This program is not a perfect recreation of the original, but it achieves artistic results all the same.  A number of "knobs" at the top of the file can be adjusted to change the output format or processing steps.

## Technical
Input images are converted to grayscale, optionally blurred, then Sobel edge detection is used to find detailed areas.  Finally, histogram equalization is applied to create a smooth progression of source range for drawing.

Note that these steps are done on floating-point grayscale values, rather than using a PImage.  Using only 8 bits lacks precision for creating the final edge image.