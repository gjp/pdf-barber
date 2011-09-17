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
# - gs (GhostScript), to write the new CropBox into the output file

module Barber
  require 'tmpdir'
  require_relative 'constants'

  class Shaver
    def initialize(params)
      @params = params
      process_params
      get_filename
    end

    def start
      read_pdf_info

      if @params[:dir]
        @tmpdir = @params[:dir]
        shave
      else
        Dir.mktmpdir do |dir|
          @tmpdir = dir
          shave
        end
      end
    end

 private

    def shave
      render_size = render
      render_center = calc_center(render_size)
      compose
      flood(render_center)
      geometry = crop_render
      calc_cropbox(geometry)
      write_cropped_pdf
    end

    def process_params
      @start_page, @end_page = @params[:range]
      @start_page ||= 2
      @end_page ||= 51 

      @composition = COMPOSITIONS[@params[:composition]] ||
        COMPOSITIONS[:default]
    end

    def get_filename
      @filename = @params[:filenames][0]

      raise RuntimeError, "An input filename is required" unless @filename
      raise RuntimeError, "Cannot open #{@filename}" unless File.readable?(@filename)
    end

    def run(command_with_args)
      command = command_with_args.split[0]
      puts 'Running: ' + command_with_args if @params[:verbose]

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
           " -gray -aa no -aaVector no -png -r 72"\
           " -f #{@start_page}"\
           " -l #{@end_page}"\
           " #{@filename} #{@tmpdir}/page")

      a_page_name = Dir.entries(@tmpdir).grep(/page/).first
      image_dimensions( "#{@tmpdir}/#{a_page_name}" )
    end

    def image_dimensions(name)
      id = run( "identify #{name}" )
      matches_to_i( id, /PNG ([\d\.]+)x([\d\.]+)/ )
    end

    def calc_scale(*render_size)
      [ render_size[0].to_f / @page_size[0], render_size[1].to_f / @page_size[1] ]
    end

    def calc_center(render_size)
      [ render_size[0] / 2, render_size[1] / 2 ]
    end

    def compose
      # Compose the PNG files generated earlier into a single image

      run("convert"\
          " #{@tmpdir}/page*"\
          " #{@composition[:method]}"\
          " #{@tmpdir}/composed.png" )
    end

    def flood(render_center)
      # Create a copy of the composed image floodfilled from the center

      run("convert #{@tmpdir}/composed.png"\
          " -fuzz 50%"\
          " -fill red"\
          " -floodfill +#{render_center[0]}+#{render_center[1]}"\
          " #{@composition[:color]}"\
          " #{@tmpdir}/filled.png" )
    end

    def crop_render
      # Remove all non-floodfilled pixels and ask what the new image size
      # and offset would be if we were to trim the edges

      geometry_str =
        run("convert #{@tmpdir}/filled.png"\
            " -fill none"\
            " +opaque red"\
            " -trim"\
            " -format '%W %H %X %Y %w %h' info:-" )
     
      @geometry = geometry_str.chomp.split.map(&:to_i)
    end

    def calc_cropbox(geometry)
      # Use the render size, cropped size, offsets, and PDF box sizes to calculate the new
      # CropBox. This part is just arithmetic.
      orig_width, orig_height, offset_x, offset_y, new_width, new_height = *geometry
      scale_width, scale_height = calc_scale(orig_width, orig_height) 
      puts "Original page size: #{@page_size}"
      l = (offset_x * scale_width).round
      t = (offset_y * scale_height).round
      r = ((offset_x + new_width) * scale_width).round
      b = ((offset_y + new_height) * scale_height).round
      @cropbox = [l,t,r,b]
      puts "New CropBox: #{l} #{t} #{r} #{b}"
    end

    def write_cropped_pdf
      puts "Writing cropped PDF..."

      output_filename = 'cropped_' + File.basename(@filename)

      run ("gs"\
           " -sDEVICE=pdfwrite" \
           " -o #{output_filename}"\
           " -c \"[/CropBox [#{@cropbox.join(' ')}] /PAGES pdfmark\""\
           " -f #{@filename}" )
    end

  end
end
