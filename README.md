# PDF Barber
A command line PDF cropping tool targeted specifically at adapting documents formatted for print to the different requirements of e-readers.

_Submitted as a Mendicant University session 9 personal project_

Books which are formatted for print often waste a lot of the limited, low-resolution screen real estate on e-readers with excessively large margins. Because PDF is a final output format, designed to look nearly identical on any display device, it does not contain the semantic data necessary to tell a reader where those margins are.

So we have to cheat.

The goal of this project is to identify a bounding box for a given PDF which contains most, but not all, of the "ink" on a range of pages within that PDF, and to create a new PDF with the CropBox adjusted to contain only those interesting bits. Page numbers, headers, and rare footnotes or marginal notes should be trimmed in order to maximize the size of the body text. Failing that, it should at least trim obvious whitespace.

## How does this work?

It renders a range of pages to raster format and composes them into a single image, somewhat like running the same piece of paper through a printer many times. For documents with obvious margins, this should produce a large black rectangle in the center of the page.

The composed image is then floodfilled from the center, and the non-floodfilled pixels are removed. The size of the remaining image is then compared to the original. The size adjustment and offset is scaled to match that of the original document. Finally, a new PDF is written with the CropBox for every page set to the new values.

## What else do I need?

Unfortunately, this is a dependency beast. You'll need all of the following:

- A *nix-like system. This tool uses several command-line tools which are operated in a virtual pipeline.
- pdfinfo and pdftoppm: Available either through the xpdf or Poppler packages. Required for rendering.
- ImageMagick. Required for processing of the rendered pages.
- PDFEdit. Required to re-write the CropBox of each page.
