"""
Image manipulation and analysis in python.

Use the `pillow` library. https://pillow.readthedocs.io/en/5.0.0/
`pip install pillow`

More information https://pillow.readthedocs.io/en/5.0.0/handbook/tutorial.html
"""

from PIL import Image

# Read in file
im = Image.open("image.png")

# Dimensions of image
im.size

# Image type
im.mode

# Display image in preview
im.show()

# Create a new image object
out = Image.new("RGBA", (100 * 20, 100 * 20), (255, 255, 255, 255))

# Iterate through a 2000 x 2000 image, perform some logic, and output
# to in-memory buffer.
# Note that this is fairly slow.
for x in range(100 * 20):
    for y in range(100 * 20):
        (r, g, b, a) = im.getpixel((x, y))
        if r not in primes:
            out.putpixel((x, y), (0, 0, 0, 255))
        #if r >= 128 and g <= 80 and b <= 80:
            # out.putpixel((x, y), (r, g, b, a))

# Processing individual bands
source = im.split()
#source is an array of Image objects for each channel.

# Do some operations on each channel then re-merge
out = Image.merge(im.mode, source)

# Iterate through the points of a channel applying some function.
# Function should map from input pixel values to output pixel values.
# Can also provide an array to perform the mapping.
# This is much faster than using getpixel/putpixel.
mask = source[0].point(lambda i: i in primes and 255)
mask.show()
