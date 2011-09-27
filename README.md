# PDF Barber
A command line PDF cropping tool targeted specifically at adapting documents formatted for print to the different requirements of e-readers.

_Submitted as a Mendicant University session 9 personal project_

Books which are formatted for print often contain large margins which waste a lot of the limited screen real estate on non-print devices, especially e-readers. Because PDF is a final output format, designed to look nearly identical on any display device, it does not contain the semantic data necessary to tell a reader where those margins are. We have to cheat to find them.

The goal of this project is to identify a bounding box for a given PDF which contains most, _but not all_, of the "ink" on a range of pages within that PDF, and to create a new PDF with the CropBox adjusted to contain only those interesting bits. Page numbers, headers, and rare footnotes or marginal notes should be trimmed in order to maximize the size of the body text.

## How does this work?

Barber renders a range of pages as very low resolution raster images and then composes them into a single image, somewhat like running the same piece of paper through a printer many times. For documents with obvious margins, this should produce a large black rectangle in the center of the page.

The composed image is then floodfilled from the center, and the non-floodfilled pixels are removed. The size of the remaining image is then compared to the original. The size adjustment and offset is scaled to match that of the original document. Finally, a new PDF is written with the CropBox set to the new values.

It's up to you to visually scan the document beforehand to find a good range of pages to use as a basis for the *required --range parameter*. It's best to skip titles, tables of contents, and pages which contain content which runs into the margins, such as large images or horizontal rules. A range of about ten pages will usually provide good results.

## Sample runs

Normal run

```
pdf-barber$ ruby bin/barber.rb --range 1-8 pdfs/bookie-basic-feature.pdf 
Page size: [504, 661] MediaBox: [0, 0, 504, 661] CropBox: [0, 0, 504, 661]
Rendering pages 1 to 8...
Render size: [252, 331]
New CropBox: [68, 76, 438, 613] Translate: [68, 76] Size: [0, 0, 370, 537]
Writing PDF with new CropBox to cropped_bookie-basic-feature.pdf...
```

You can add a --verbose flag if you *really* want to know what it's doing...

```
pdf-barber$ ruby bin/barber.rb --verbose --range 10-19 pdfs/A_Tale_of_Two_Cities_NT.pdf 
Running: pdfinfo -box pdfs/A_Tale_of_Two_Cities_NT.pdf
Page size: [385, 525] MediaBox: [0, 0, 612, 792] CropBox: [113, 255, 498, 780]
Rendering pages 10 to 19...
Running: pdftoppm -gray -aa no -aaVector no -png -r 36 -f 10 -l 19 pdfs/A_Tale_of_Two_Cities_NT.pdf /tmp/d20110926-8711-eofvnb/barber-page
Running: identify /tmp/d20110926-8711-eofvnb/barber-page-019.png
Render size: [306, 396]
Running: convert /tmp/d20110926-8711-eofvnb/barber-page* -compose multiply -flatten -blur 4 -normalize /tmp/d20110926-8711-eofvnb/composed.png
Running: convert /tmp/d20110926-8711-eofvnb/composed.png -fuzz 50% -fill red -floodfill +153+198 gray /tmp/d20110926-8711-eofvnb/filled.png
Running: convert /tmp/d20110926-8711-eofvnb/filled.png -fill none +opaque red -trim -format '%W %H %X %Y %w %h' info:-
New CropBox: [160, 320, 450, 722] Translate: [160, 320] Size: [0, 0, 290, 402]
Writing PDF with new CropBox to cropped_A_Tale_of_Two_Cities_NT.pdf...
Running: gs -sDEVICE=pdfwrite -o cropped_A_Tale_of_Two_Cities_NT.pdf -c "[/CropBox [160 320 450 722] /PAGES pdfmark"  -f /tmp/d20110926-8711-eofvnb/barber20110926-8711-15vg8np
```
Other options:

`--dryrun` will display the calculated CropBox without writing a new file.

`--tmpdir DIR` will render the working files to the specified directory and retain them, so you can see what the renderer is doing. WARNING: Using the same tmpdir for multiple runs will cause odd behavior.

## What else do I need?

Unfortunately, this is a dependency beast. You'll need all of the following:

- A *nix-like system. This tool uses several command-line tools which are operated in a virtual pipeline.
- pdfinfo and pdftoppm: Available either through the xpdf or Poppler packages. Required for rendering.
- ImageMagick. Required for processing of the rendered pages.
- GhostScript. Required to re-write the CropBox of each page.

Future versions _may_ reduce this to GhostScript and ImageMagick, or lighter-weight tools if they become available.

## What about the API?

Barber is intended to be used by a person, from a command line. You need to eyeball each document to find a page range. But if you really want to, you can tell the Barber to give himself a shave:

```
require_relative 'lib/barber'
Barber::Shaver.shave(filename: 'pdfs/bookie-basic-feature.pdf', range: [1,8])
```
