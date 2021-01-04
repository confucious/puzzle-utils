# Requires python3 and PIL.
# PIL can be intstalled by `python3 -m pip install Pillow`.
# Run this by `python3 image-segmenter.py <input files>`.
# It will output numbered files prefixed as out-<n>.png
# It expects RGB png files and will probably crash with grayscale.
# Suggest using 72 dpi if converting PDFs to PNGs.

# Algorithm:
# 1) Grow
# Maintain set of continguous shapes.
# Scan lines and look for candidate pixels.
# For pixel, check neighbors (don't need to check, right, down, down right, or down left).
#  If any neighbors found in existing sets, then merge those sets and add pixel to the set.
#  Else start a new set with the pixel.
#
# 2) Copy
# Flood fill on set starting at minX - 1, minY-1 to determine exterior pixels.
# Copy all pixels from source from minX, minY to maxX, maxY.
# Set exterior pixels to background.

from PIL import Image
import glob, sys

class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __eq__(self, other):        
        return isinstance(other, Point) and self.x == other.x and self.y == other.y

    def __hash__(self):
        return hash((self.x, self.y))

    def offset(self, deltaX, deltaY):
        return Point(self.x + deltaX, self.y + deltaY)

def segment(filename):
    print("Processing {}".format(filename))
    # Read in file
    im = Image.open(filename)

    # Dimensions of image
    (width, height) = im.size


    segments = []

    print("Finding segments")
    # Find segments
    for (index, pixel) in enumerate(im.getdata()):
        x = index % width
        y = index // width
        if min(pixel) == 255:
            pass
        else:
            p = Point(x, y)
            candidates = {p.offset(-1, -1), p.offset(-1, 0), p.offset(0, -1), p.offset(1, -1)}
            matchingSets = []
            for segment in segments:
                if len(segment.intersection(candidates)) > 0:
                    matchingSets.append(segment)
            if len(matchingSets) > 1:
                unionSet = set()
                for matchingSet in matchingSets:
                    segments.remove(matchingSet)
                    unionSet |= matchingSet
                unionSet.add(p)
                segments.append(unionSet)
            elif len(matchingSets) == 1:
                matchingSets[0].add(p)
            else:
                segments.append({p})

    print("Starting copies")
    # Copy
    results = []
    for segment in segments:
        for p in segment: break
        minX = p.x
        maxX = p.x
        minY = p.y
        maxY = p.y
        for point in segment:
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        minX -= 1
        minY -= 1
        maxX += 1
        maxY += 1
        current = Point(minX, minY)
        outside = {current}
        seen = set()
        active = [current]
        while len(active) > 0:
            current = active.pop()
            for candidate in [current.offset(-1, 0), current.offset(0, -1), current.offset(1, 0), current.offset(0, 1)]:
                if candidate not in segment and candidate not in seen and candidate.x >= minX and candidate.x <= maxX and candidate.y >= minY and candidate.y <= maxY:
                    outside.add(candidate)
                    active.append(candidate)
                seen.add(candidate)
        minX += 1
        maxX -= 1
        minY += 1
        maxY -= 1
        outWidth = maxX - minX + 1
        outHeight = maxY - minY + 1
        if outHeight < 25:
            #print("Skipping small image sized {} x {}".format(outWidth, outHeight))
            continue
        segmentImage = im.crop((minX, minY, maxX + 1, maxY + 1))
        out = Image.new("RGBA", (outWidth, outHeight), (255, 255, 255, 0))
        cropData = segmentImage.getdata()
        trimmedData = []
        for (index, pixel) in enumerate(cropData):
            x = index % outWidth
            y = index // outWidth
            if Point(x + minX, y + minY) not in outside:
                trimmedData.append((pixel[0], pixel[1], pixel[2], 255))
            else:
                trimmedData.append((255, 255, 255, 0))
        out.putdata(trimmedData)
        results.append(out)
        print("Found image sized {} x {}".format(outWidth, outHeight))
    return results

results = []
for arg in sys.argv[1:]:
    for filename in glob.glob(arg):
        results.extend(segment(filename))

for (index, image) in enumerate(results):
    image.save("out-{}.png".format(index))
