# PDF Barber: a personal project for Mendicant University session 9
# Gregory Parkhurst
#
# See README for background information.
#
# This utility relies on the commands pdfinfo and pdftoppm, available either through
# the xpdf or Poppler distributions, and the ImageMagick convert command.

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

      render_pages
      get_render_size
      calc_center_and_scale
      compose_and_fill
      find_bounding_box
      crop
    end
  end

private

  def process_options
    if @options[:range]
      @start_page, @end_page = @options[:range].match(/(\d+)\-(\d+)/)[1,2].map(&:to_i)
    end

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

    @pages     = pdfinfo.match(/Pages:\s+(\d+)/)[1].to_i
    @page_size = pdfinfo.match(/Page size:\s+([\d\.]+) x ([\d\.]+)/)[1,2].map(&:to_i)

    boxre = '\s+([\d\.]+)' * 4
    @mediabox = pdfinfo.match(/MediaBox:#{boxre}/)[1,4].map(&:to_i)
    @cropbox  = pdfinfo.match(/CropBox:#{boxre}/)[1,4].map(&:to_i)

    if @mediabox != @cropbox
      puts "Warning: CropBox #{@cropbox} does not match MediaBox #{@mediabox}"
    end
  end

  def render_pages
    puts "Rendering pages #{@start_page} to #{@end_page}..."

    run ("pdftoppm -gray -aa no -png -r 72"\
         " -f #{@start_page}"\
         " -l #{@end_page}"\
         " #{@filename} #{@tmpdir}/page")
  end

  def get_render_size
    first_image = "page-#{"%03d" % @start_page}.png"
    renderinfo = run( "identify #{@tmpdir}/#{first_image}" )

    @image_size = renderinfo.match(/PNG ([\d\.]+)x([\d\.]+)/)[1,2].map(&:to_i)
  end

  def calc_center_and_scale
    @center_x = @image_size[0] / 2
    @center_y = @image_size[1] / 2

    @scale_x = @image_size[0].to_f / @page_size[0]
    @scale_y = @image_size[1].to_f / @page_size[1]

    puts "Assuming content centered at #{@center_x} #{@center_y}" if @options[:verbose]
  end

  def compose_and_fill
    flood_params = "-floodfill +#{@center_x}+#{@center_y} #{@composition[1]}"
    run( "convert #{@tmpdir}/page* #{@composition[0]} #{flood_params} out.png" )
  end

  def find_bounding_box
  end

  def crop
  end

end

#####

Barber.new.shave
