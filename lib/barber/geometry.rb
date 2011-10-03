module Barber
  class Geometry
    include Helpers

    attr_accessor :render_dimensions
    attr_reader   :mediabox, :cropbox, :pagesize, :pages

    def initialize(mediabox, pages = 'all')
      @mediabox = mediabox
      @pages = pages
      @render_dimensions = []
    end

    def calc_cropbox(render_geometry)
      # Use the render size, cropped size, offsets, and PDF box sizes to
      # calculate the new CropBox. This part is just arithmetic.

      render_width, render_height, offset_left,
      offset_top, crop_width, crop_height = *render_geometry

      scale_width = media_width.to_f / render_width.to_f
      scale_height = media_height.to_f / render_height.to_f

      # The PDF coordinate system is based at the lower left of the page,
      # whereas the raster coordinate system is based at the upper left
      l = (offset_left * scale_width).round
      b = ((render_height - (crop_height + offset_top)) * scale_height).round
      r = ((crop_width + offset_left) * scale_width).round
      t = ((render_height - offset_top) * scale_height).round

      @cropbox = [l, b, r, t]
      @pagesize = [ (crop_width * scale_width).round,
                    (crop_height * scale_height).round ]
    end

    def cropbox_s
      @cropbox.join(' ')
    end

    def pagesize_s
      @pagesize.join(' ')
    end

    def new_pagesize
      [ @newbox[2] - @newbox[0], @newbox[3] - @newbox[1] ]
    end

    def media_width
      @mediabox[2] - @mediabox[0]
    end

    def media_height
      @mediabox[3] - @mediabox[1]
    end

    def render_width
      @render_dimensions[0]
    end

    def render_height
      @render_dimensions[1]
    end

    def render_center_x
      @render_dimensions[0] / 2
    end

    def render_center_y
      @render_dimensions[1] / 2
    end

    def show_new_boxes
      feedback(
        "New CropBox for #{@pages} pages: #{@cropbox} Page Size: #{@pagesize}"
      )
    end 

  end
end
