module Barber
  class Renderer
    include Helpers

    # The default composition method works well, but other methods may work
    # better for other types of content.

    COMPOSITIONS = {
      :default  => {method: '-compose multiply -flatten -blur 4 -normalize',
                    color: 'gray'},
      :average  => {method: '-average',
                    color: 'lightgray'},
    }

    def initialize(geometry, params)
      @params = params
      @geometry = geometry
      @tmpdir = params[:tmpdir]
    end

    def render
      @geometry.rendersize = render_pages(@params[:filename], @params[:range])
      @geometry.puts_rendersize

      composition =
        COMPOSITIONS[@params[:composition]] || COMPOSITIONS[:default]

      compose(composition[:method])
      flood(composition[:color])
    end

    def render_pages(filename, page_range)
      # Render a range of pages as low-resolution grayscale PNG files
      # Give some feedback; this can take time if the page range is large

      start_page, end_page = *page_range
      feedback("Rendering pages #{start_page} to #{end_page}...")

      system_command(
        "pdftoppm"\
        " -gray"\
        " -aa no"\
        " -aaVector no"\
        " -png"\
        " -r 36"\
        " -f #{start_page}"\
        " -l #{end_page}"\
        " #{filename} #{@tmpdir}/barber-page",
        @params
      )

      a_page_name = Dir.entries(@tmpdir).grep(/barber-page/).first
      image_dimensions( "#{@tmpdir}/#{a_page_name}" )
    end

    def image_dimensions(name)
      id = system_command( "identify #{name}", @params )
      matches_to_i( id, /PNG ([\d\.]+)x([\d\.]+)/ )
    end

    def compose(composition_method)
      # Compose the PNG files generated earlier into a single image
      
      system_command(
        "convert"\
        " #{@tmpdir}/barber-page*"\
        " #{composition_method}"\
        " #{@tmpdir}/composed.png",
        @params
      )
    end

    def flood(composition_color)
      # Create a copy of the composed image floodfilled from the center

      system_command(
        "convert #{@tmpdir}/composed.png"\
        " -fuzz 50%"\
        " -fill red"\
        " -floodfill"\
        " +#{@geometry.render_center_x}+#{@geometry.render_center_y}"\
        " #{composition_color}"\
        " #{@tmpdir}/filled.png",
        @params
      )
    end

    def find_crop_geometry
      # Remove all non-floodfilled pixels and find what the new image size
      # and offset would be if we were to trim the edges

      geometry_str =
        system_command(
          "convert #{@tmpdir}/filled.png"\
          " -fill none"\
          " +opaque red"\
          " -trim"\
          " -format '%W %H %X %Y %w %h' info:-",
          @params
        )
     
       geometry_str.chomp.split.map(&:to_i)
    end
  end
end
