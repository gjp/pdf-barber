# PDF Barber
A command line PDF cropping tool targeted specifically at e-readers.

_Submitted as a Mendicant University session 9 personal project_

Books which are formatted for print often waste a lot of the limited, low-resolution screen real estate on e-readers with excessively large margins. Because PDF is a final output format, designed to look nearly identical on any display device, most (all?) PDF files lack the ability to reflow text, or even contain the concept of margins.

The goal of this project is to identify a bounding box for a given PDF which contains most, but not all, of the "ink" on a range of pages within that PDF, and to create a new PDF with the CropBox adjusted to contain only those interesting bits.

Page numbers, headers, and rare footnotes or marginal notes should be trimmed in preference to maximizing the size of the body text. Failing that, it should at least trim obvious whitespace.


