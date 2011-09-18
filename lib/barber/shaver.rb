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

  class Shaver

    # Some amount of eyeballing will always be required in order for this to work;
    # multiple composition methods will allow for some flexibility in determining
    # the bounding box
   
    COMPOSITIONS = {
      :default  => {method: '-compose multiply -flatten -blur 4 -normalize',
                    color: 'gray'},
      :average  => {method: '-average',
                    color: 'lightgray'},
    }

    def initialize(params)
      @params = params
      process_params
      get_filename
    end

    def start
      @geometry = read_pdf_info(Geometry.new)

      if @params[:tmpdir]
        @tmpdir = @params[:tmpdir]
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
      @geometry.puts_original_boxes
      @geometry.rendersize = render_pages
      @geometry.puts_rendersize

      compose(@tmpdir, @composition[:method])
      flood(@tmpdir, @composition[:color], @geometry)

      @geometry.calc_newbox(crop(@tmpdir))
      @geometry.puts_new_boxes

      write_pdf_cropbox(@geometry, @filename)
    end

    def process_params
      @start_page, @end_page = @params[:range]
      @start_page ||= 2
      @end_page ||= 51 

      @composition = COMPOSITIONS[@params[:composition]] || COMPOSITIONS[:default]
    end

    def get_filename
      @filename = @params[:filenames][0]

      raise BarberError, "An input filename is required" unless @filename
      raise BarberError, "Cannot open #{@filename}" unless File.readable?(@filename)
    end

    def run(command_with_args)
      command = command_with_args.split[0]
      puts 'Running: ' + command_with_args if @params[:verbose]

      result  = `#{command_with_args}`
      raise BarberError, "command failed" if $?.exitstatus > 0

      result
    end

    def read_pdf_info(geometry)
      # May need to expand this to gather box data for all pages.
      # Some PDFs apparently use the TrimBox for per-page masking? Just a guess.

      pdfinfo = run( "pdfinfo -box #{@filename}" )

      num_re = '\s+([\d\.]+)'

      @pages            = matches_to_i( pdfinfo, /Pages:#{num_re}/ )
      geometry.pagesize = matches_to_i( pdfinfo, /Page size:#{num_re} x#{num_re}/ )
      geometry.mediabox = matches_to_i( pdfinfo, /MediaBox:#{num_re * 4}/ )
      geometry.cropbox  = matches_to_i( pdfinfo, /CropBox:#{num_re * 4}/ )
      geometry
    end

    def matches_to_i(str, re)
      m = str.match(re).to_a
      m.shift
      m.map(&:to_i)
    end

    def render_pages
      # Render a range of pages as low-resolution grayscale PNG files
      # Give some feedback; this can take time if the page range is large

      puts "Rendering pages #{@start_page} to #{@end_page}..."

      run ("pdftoppm"\
           " -gray"\
           " -aa no"\
           " -aaVector no"\
           " -png"\
           " -r 72"\
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
        def compose(tmpdir, composition_method)
      # Compose the PNG files generated earlier into a single image
      
      run("convert"\
          " #{tmpdir}/page*"\
          " #{composition_method}"\
          " #{tmpdir}/composed.png" )
    end

    def flood(tmpdir, composition_color, geometry)
      # Create a copy of the composed image floodfilled from the center

      run("convert #{tmpdir}/composed.png"\
          " -fuzz 50%"\
          " -fill red"\
          " -floodfill +#{geometry.render_center_x}+#{geometry.render_center_y}"\
          " #{composition_color}"\
          " #{tmpdir}/filled.png" )
    end

    def crop(tmpdir)
      # Remove all non-floodfilled pixels and find what the new image size
      # and offset would be if we were to trim the edges

      geometry_str =
        run("convert #{tmpdir}/filled.png"\
            " -fill none"\
            " +opaque red"\
            " -trim"\
            " -format '%W %H %X %Y %w %h' info:-" )
     
       geometry_str.chomp.split.map(&:to_i)
    end

    def write_pdf_cropbox(geometry, filename)
      puts "Writing PDF with CropBox..."

      output_filename = 'cropped_' + File.basename(filename)

      run ("gs"\
           " -sDEVICE=pdfwrite" \
           " -o #{output_filename}"\
           " -c \"[/CropBox [#{geometry.newbox_s}] /PAGES pdfmark\" "\
           " -f #{filename}" )
    end

    def write_pdf_rectclip(geometry, filename)
      puts "Writing PDF with rectclip..."

      output_filename = 'cropped_' + File.basename(filename)

      run ("gs"\
           " -sDEVICE=pdfwrite"\
           " -o #{output_filename}"\
           " -dDEVICEWIDTHPOINTS=#{geometry.media_width}"\
           " -dDEVICEHEIGHTPOINTS=#{geometry.media_height}"\
           " -dFIXEDMEDIA"\
           " -c \"#{geometry.translate_s} translate"\
           "      #{geometry.rectclip_s} rectclip\" " \
           " -f #{filename}" )
    end

  end
end
