module Barber
  class Geometry
    attr_accessor :pagesize, :mediabox, :cropbox, :rendersize
    attr_reader   :newbox, :translate, :rectclip

    def initialize
      @pagesize = []
      @mediabox = []
      @cropbox = []
      @rendersize = []
      @newbox = []
      @rectclip = []
      @translate = []
    end

    def calc_newbox(render_geometry)
      # Use the render size, cropped size, offsets, and PDF box sizes to calculate
      # the new CropBox. This part is just arithmetic.

      render_width, render_height, offset_left, offset_top, crop_width, crop_height =
        *render_geometry

      scale_width = media_width.to_f / render_width.to_f
      scale_height = media_height.to_f / render_height.to_f

      # The PDF coordinate system is based at the lower left of the page,
      # whereas the raster coordinate system is based at the upper left
      l = (offset_left * scale_width).round
      b = ((render_height - (crop_height + offset_top)) * scale_height).round
      r = ((crop_width + offset_left) * scale_width).round
      t = ((render_height - offset_top) * scale_height).round

      @newbox = [l, b, r, t]
      @translate = [l, b]
      @rectclip = [0, 0, (crop_width * scale_width).round, (crop_height * scale_height).round ]
    end

    def newbox_s
      @newbox.join(' ')
    end

    def rectclip_s
      @rectclip.join(' ')
    end

    def translate_s
      @translate.join(' ')
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
      @rendersize[0]
    end

    def render_height
      @rendersize[1]
    end

    def render_center_x
      @rendersize[0] / 2
    end

    def render_center_y
      @rendersize[1] / 2
    end

    def puts_original_boxes
      puts "Page size: #{@pagesize} MediaBox: #{@mediabox} CropBox: #{@cropbox}"
    end 

    def puts_new_boxes
      puts "NewBox: #{@newbox} Translate: #{@translate} Rectclip: #{@rectclip}"
    end 

    def puts_rendersize
      puts "Rendersize: #{@rendersize}"
    end
  end
end
