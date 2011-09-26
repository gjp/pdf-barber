module Barber
  class Writer
    include Helpers 

    def initialize(geometry, options)
      @geometry = geometry
      @options = options
      @filename = options[:filename]
      @output_filename = 'cropped_' + File.basename(@filename)
    end

    def write
      clear_existing_cropboxes 
    end

    def clear_existing_cropboxes
      File.open(@filename, 'rb') do |f|
        Tempfile.open('barber', @options[:tmpdir]) do |tf|
          pdfdata = f.read
          pdfdata.gsub!(/(\/CropBox\[[^\[]+\])/) { |s| ' ' * s.size }
          tf.write(pdfdata)
          write_new_cropbox(tf.path)
        end
      end
    end

    def write_new_cropbox(filename)
      feedback(
        "Writing PDF with new CropBox to #{@output_filename}..."
      )

      system_command(
        "gs"\
        " -sDEVICE=pdfwrite" \
        " -o #{@output_filename}"\
        " -c \"[/CropBox [#{@geometry.newbox_s}] /PAGES pdfmark\" "\
        " -f #{filename}",
        @options
      )
    end
  end
end
