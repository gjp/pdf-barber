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
    include Helpers

    def self.shave(params)
      if params[:tmpdir]
        new.run(params)
      else
        Dir.mktmpdir do |dir|
          params[:tmpdir] = dir
          new.run(params)
        end
      end
    end

    def run(params)
      geometry = Reader.new( params ).read
      geometry.puts_original_boxes

      check_page_range( geometry.pages, params[:range] )

      renderer = Renderer.new( geometry, params )
      renderer.render

      geometry.calc_newbox( renderer.find_crop_geometry )
      geometry.puts_new_boxes

      Writer.new( geometry, params ).write
    end
  end
end
