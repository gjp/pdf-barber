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
  #include Runner

  class Shaver
    def initialize(params)
      @params = params
    end

    def start
      if @params[:tmpdir]
        shave(@params)
      else
        Dir.mktmpdir do |dir|
          @params[:tmpdir] = dir
          shave(@params)
        end
      end
    end

 private

    def shave(params)
      reader = Reader.new(params)
      geometry = reader.read
      geometry.puts_original_boxes

      renderer = Renderer.new(geometry, params)
      renderer.render

      geometry.calc_newbox(renderer.find_crop_geometry)
      geometry.puts_new_boxes

      Writer.new(geometry, params).write
    end
  end
end
