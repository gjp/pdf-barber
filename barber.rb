# PDF Barber: a personal project for Mendicant University session 9
# Gregory Parkhurst
#
# See README for background information.
#
# This utility relies on the following commands:
#
# - pdfinfo and pdftoppm, available either through xpdf or Poppler,
#   to gather box info from the file and to render pages
# - convert and indentify, available as components of ImageMagick,
#   to manipulate the rendered pages as raster images
# - pdfedit, to write the new CropBox into the output file

require 'tmpdir'
require_relative 'lib/options'
require_relative 'lib/constants'

class Barber
  include Options

  def initialize
    @options = {}
    get_options 
    process_options
    get_filename
  end

  def shave
    read_pdf_info

    Dir.mktmpdir do |dir|
      @tmpdir = dir

      render
      get_render_size
      calc_center
      compose
      flood
      crop
    end
  end

private

  def process_options
    @start_page, @end_page = @options[:range]
    @start_page ||= 2
    @end_page ||= 51 

    @composition = COMPOSITIONS[@options[:composition]] ||
                   COMPOSITIONS[:default]
  end

  def get_filename
    @filename = ARGV[0]

    raise RuntimeError, "An input filename is required" unless @filename
    raise RuntimeError, "Cannot open #{@filename}" unless File.readable?(@filename)
  end

  def run(command_with_args)
    command = command_with_args.split[0]
    puts 'Running: ' + command_with_args if @options[:verbose]

    result  = `#{command_with_args}`
    raise RuntimeError, "command failed" if $?.exitstatus > 0

    result
  end

 def read_pdf_info
    # May need to expand this to gather box data for all pages.
    # Some PDFs apparently use the TrimBox for per-page masking? Just a guess.

    pdfinfo = run( "pdfinfo -box #{@filename}" )

    num_re = '\s+([\d\.]+)'

    @pages     = matches_to_i( pdfinfo, /Pages:#{num_re}/ )
    @page_size = matches_to_i( pdfinfo, /Page size:#{num_re} x#{num_re}/ )
    @mediabox  = matches_to_i( pdfinfo, /MediaBox:#{num_re * 4}/ )
    @cropbox   = matches_to_i( pdfinfo, /CropBox:#{num_re * 4}/ )

    if @mediabox != @cropbox
      puts "Warning: CropBox #{@cropbox} does not match MediaBox #{@mediabox}"
    end
  end

  def matches_to_i(str, re)
    m = str.match(re).to_a
    m.shift
    m.map(&:to_i)
  end
 
  def render
    # Render a range of pages as low-resolution grayscale PNG files
    # Give some feedback; this can take time if the page range is large

    puts "Rendering pages #{@start_page} to #{@end_page}..."

    run ("pdftoppm"\
         " -gray -aa no -png -r 72"\
         " -f #{@start_page}"\
         " -l #{@end_page}"\
         " #{@filename} #{@tmpdir}/page")
  end

  def image_dimensions(name)
    id = run( "identify #{name}" )
    matches_to_i( id, /PNG ([\d\.]+)x([\d\.]+)/ )
  end

  def get_render_size
    first_image = "page-#{"%03d" % @start_page}.png"
    @render_size = image_dimensions( "#{@tmpdir}/#{first_image}" )
  end

  def calc_scale
    @scale_x = @render_size[0].to_f / @page_size[0]
    @scale_y = @render_size[1].to_f / @page_size[1]
  end

  def calc_center
    @center_x = @render_size[0] / 2
    @center_y = @render_size[1] / 2
  end

  def compose
    # Compose the PNG files generated earlier into a single image

    run("convert"\
        " #{@tmpdir}/page*"\
        " #{@composition[:method]}"\
        " #{@tmpdir}/composed.png" )
  end

  def flood
    # Create a copy of the composed image floodfilled from the center

    run("convert #{@tmpdir}/composed.png"\
        " -fuzz 50%"\
        " -fill red"\
        " -floodfill +#{@center_x}+#{@center_y}"\
        " #{@composition[:color]}"\
        " #{@tmpdir}/filled.png" )
  end

  def crop
    # Create an image which contains only the changes between the composed and filled images
    # This is a proof-of-concept - we need the x,y offsets as well as the cropped size
    # unless the crop is centered. This can be done by marking the non-floodfilled area
    # as transparent, but I haven't completed that part yet.

    run("convert #{@tmpdir}/composed.png"\
        " #{@tmpdir}/filled.png"\
        " -deconstruct"\
        " cropped.png" )

    @crop_size = image_dimensions('cropped-1.png')
    puts "Render size is #{@render_size}, crop size is #{@crop_size}"
  end

  def calc_cropbox
    # Use the render size, cropped size, offsets, and PDF box sizes to calculate the new
    # CropBox. This part is just arithmetic.
  end

  def write_cropped_pdf
    # Most likely a pdfedit script.
  end

end

#####

Barber.new.shave
