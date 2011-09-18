# PDF Barber
A command line PDF cropping tool targeted specifically at adapting documents formatted for print to the different requirements of e-readers.

_Submitted as a Mendicant University session 9 personal project_

Books which are formatted for print often waste a lot of the limited, low-resolution screen real estate on e-readers with excessively large margins. Because PDF is a final output format, designed to look nearly identical on any display device, it does not contain the semantic data necessary to tell a reader where those margins are.

We have to cheat.

The goal of this project is to identify a bounding box for a given PDF which contains most, _but not all_, of the "ink" on a range of pages within that PDF, and to create a new PDF with the CropBox adjusted to contain only those interesting bits. Page numbers, headers, and rare footnotes or marginal notes should be trimmed in order to maximize the size of the body text. Failing that, it should at least trim obvious whitespace.

## How does this work?

It renders a range of pages to raster format and composes them into a single image, somewhat like running the same piece of paper through a printer many times. For documents with obvious margins, this should produce a large black rectangle in the center of the page.

The composed image is then floodfilled from the center, and the non-floodfilled pixels are removed. The size of the remaining image is then compared to the original. The size adjustment and offset is scaled to match that of the original document. Finally, a new PDF is written with the CropBox for every page set to the new values.

It's up to you to visually scan the document beforehand to find a good range of pages to use as a basis for the --range parameter. It's best to skip titles, tables of contents, and pages which contain content which runs into the margins, such as large images or horizontal rules.

## Sample runs

Normal

```
pdf-barber/pdfs$ ruby ../bin/barber.rb --range 10-20 tbmms10p.pdf 
Page size: [612, 792] MediaBox: [0, 0, 612, 792] CropBox: [0, 0, 612, 792]
Rendering pages 10 to 20...
Rendersize: [612, 792]
NewBox: [131, 117, 480, 667] Translate: [131, 117] Rectclip: [0, 0, 349, 550]
Writing PDF with CropBox...
```

Verbose!

```
pdf-barber/pdfs$ ruby ../bin/barber.rb --verbose --range 1-8 bookie-basic-feature.pdf 
Running: pdfinfo -box bookie-basic-feature.pdf
Page size: [504, 661] MediaBox: [0, 0, 504, 661] CropBox: [0, 0, 504, 661]
Rendering pages 1 to 8...
Running: pdftoppm -gray -aa no -aaVector no -png -r 72 -f 1 -l 8 bookie-basic-feature.pdf /tmp/d20110918-25824-7jc4g/page
Running: identify /tmp/d20110918-25824-7jc4g/page-5.png
Rendersize: [504, 662]
Running: convert /tmp/d20110918-25824-7jc4g/page* -compose multiply -flatten -blur 4 -normalize /tmp/d20110918-25824-7jc4g/composed.png
Running: convert /tmp/d20110918-25824-7jc4g/composed.png -fuzz 50% -fill red -floodfill +252+331 gray /tmp/d20110918-25824-7jc4g/filled.png
Running: convert /tmp/d20110918-25824-7jc4g/filled.png -fill none +opaque red -trim -format '%W %H %X %Y %w %h' info:-
NewBox: [70, 78, 435, 610] Translate: [70, 78] Rectclip: [0, 0, 365, 532]
Writing PDF with CropBox...
Running: gs -sDEVICE=pdfwrite -o cropped_bookie-basic-feature.pdf -c "[/CropBox [70 78 435 610] /PAGES pdfmark"  -f bookie-basic-feature.pdf

```

## What else do I need?

Unfortunately, this is a dependency beast. You'll need all of the following:

- A *nix-like system. This tool uses several command-line tools which are operated in a virtual pipeline.
- pdfinfo and pdftoppm: Available either through the xpdf or Poppler packages. Required for rendering.
- ImageMagick. Required for processing of the rendered pages.
- GhostScript. Required to re-write the CropBox of each page.

## Known Issues

- Some PDFs won't have the new CropBox applied, possibly because it's already set per-page. I'm looking into this.
- GhostScript has been known to segfault
