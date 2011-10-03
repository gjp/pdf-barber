module Barber
  class Composer
    include Helpers

    def initialize(geometry, images, params)
      @geometry = geometry
      @images = images
      @params = params
      @pages = geometry.pages
      @tmpdir = params[:tmpdir]

      @composed_image = "#{@tmpdir}/composed_#{@pages}.png"
      @filled_image   = "#{@tmpdir}/filled_#{@pages}.png"
    end

    def compose
      compose_images
      floodfill
      detect_blob
    end

    private

    def detect_blob
      # Remove all non-floodfilled pixels and find what the new image size
      # and offset would be if we were to trim the edges

      geometry_str =
        system_command(
          "convert #{@filled_image}"\
          " -fill none"\
          " +opaque red"\
          " -trim"\
          " -format '%W %H %X %Y %w %h' info:-",
          @params
      )

      @geometry.calc_cropbox (
        geometry_str.chomp.split.map(&:to_i)
      )
    end

    def compose_images
      # Compose the PNG files generated earlier into a single image
      
      system_command(
        "convert"\
        " -compose multiply"\
        " -flatten"\
        " -blur 4"\
        " -normalize"\
        " #{@images}"\
        " #{@composed_image}",
        @params
      )
    end

    def floodfill
      # Create a copy of the composed image floodfilled from the center

      system_command(
        "convert #{@composed_image}"\
        " -fuzz 50%"\
        " -fill red"\
        " -floodfill"\
        " +#{@geometry.render_center_x}+#{@geometry.render_center_y}"\
        " gray"\
        " #{@filled_image}",
        @params
      )
    end

  end
end

