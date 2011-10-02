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
          write_new_cropbox_per_page(tf.path)
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

    def write_new_cropbox_per_page(filename)
      gscommand = <<-EOF
        File dup (r) file runpdfbegin
        1 1 pdfpagecount {
          pdfgetpage
          mark /CropBox [#{@geometry.newbox_s}] /PAGE pdfmark
          pdfshowpage
        } for
      EOF

      feedback(
        "Writing PDF with new per-page CropBox to #{@output_filename}..."
      )

      Tempfile.open('gscommand') do |f|
        f.puts(gscommand)
        f.flush

        system_command(
          "gs"\
          " -sDEVICE=pdfwrite"\
          " -dBATCH -q"\
          " -o #{@output_filename}"\
          " -sFile=#{filename}"\
          " #{f.path}",
          @options
        )
      end
    end
  end
end
