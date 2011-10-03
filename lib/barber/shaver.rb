# PDF Barber: a personal project for Mendicant University session 9
# Gregory Parkhurst
#
# See README for background information.
#
# This utility relies on the following commands:
#
# - gs (GhostScript), to read and write PDF files
# - convert and identify, available as components of ImageMagick,
#   to manipulate the rendered pages as raster images

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
      reader = Reader.new( params ).read
      reader.show_original_boxes

      geometries = []

      if params[:separate]
        geometries << Geometry.new( reader.mediabox, 'odd')
        geometries << Geometry.new( reader.mediabox, 'even')
      else
        geometries << Geometry.new( reader.mediabox, 'all')
      end

      renderer = Renderer.new( params ).render

      geometries.each do |g|
        g.render_dimensions = renderer.dimensions
        Composer.new( g, params ).compose
        g.show_new_boxes
      end

      Writer.new( geometries, params ).write unless params[:dryrun]
    end
  end
end
