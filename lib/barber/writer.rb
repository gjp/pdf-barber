module Barber
  class Writer
    include Helpers 

    def initialize(geometries, options)
      @odd_geometry = geometries[0]
      @even_geometry = (geometries.size > 1 ? geometries[1] : geometries[0])
      @options = options
      @filename = options[:filename]
      @output_filename = 'cropped_' + File.basename(@filename)
    end

    def write
      File.open(@filename, 'rb') do |f|
        Tempfile.open('barber', @options[:tmpdir]) do |tf|
          pdfdata = f.read
          tf.write( clear_cropboxes(pdfdata) )
          write_new_cropboxes(tf.path)
        end
      end
    end

    private

    def clear_cropboxes(pdfdata)
      pdfdata.gsub(/(\/CropBox\[[^\[]+\])/) { |s| ' ' * s.size }
    end

    def write_new_cropboxes(filename)
      feedback(
        "Writing PDF with new CropBox to #{@output_filename}..."
      )

      ps_path = File.dirname(__FILE__)

      system_command(
        "gs"\
        " -q"\
        " -sDEVICE=pdfwrite"\
        " -sFile=#{filename}"\
        " -dBATCH"\
        " -dOddBoxLLX=#{@odd_geometry.cropbox[0]}"\
        " -dOddBoxLLY=#{@odd_geometry.cropbox[1]}"\
        " -dOddBoxURX=#{@odd_geometry.cropbox[2]}"\
        " -dOddBoxURY=#{@odd_geometry.cropbox[3]}"\
        " -dEvenBoxLLX=#{@even_geometry.cropbox[0]}"\
        " -dEvenBoxLLY=#{@even_geometry.cropbox[1]}"\
        " -dEvenBoxURX=#{@even_geometry.cropbox[2]}"\
        " -dEvenBoxURY=#{@even_geometry.cropbox[3]}"\
        " -o #{@output_filename}"\
        " #{ps_path}/pdf_set_cropbox.ps",
        @options
      )
    end
  end
end
