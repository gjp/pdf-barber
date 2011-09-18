module Barber
  class Writer
    def initialize(geometry, options)
      @geometry = geometry
      @options = options
      @filename = options[:filename]
      @output_filename = 'cropped_' + File.basename(@filename)
    end

    def write
      write_pdf_cropbox
    end

    def write_pdf_cropbox
      puts "Writing PDF using CropBox..."

      Utils.system_command(
        "gs"\
        " -sDEVICE=pdfwrite" \
        " -o #{@output_filename}"\
        " -c \"[/CropBox [#{@geometry.newbox_s}] /PAGES pdfmark\" "\
        " -f #{@filename}",
        @options
      )
    end

    def write_pdf_rectclip
      puts "Writing PDF using rectclip..."

      Utils.system_command(
        "gs"\
        " -sDEVICE=pdfwrite"\
        " -o #{@output_filename}"\
        " -dDEVICEWIDTHPOINTS=#{@geometry.media_width}"\
        " -dDEVICEHEIGHTPOINTS=#{@geometry.media_height}"\
        " -dFIXEDMEDIA"\
        " -c \"#{@geometry.translate_s} translate"\
        "      #{@geometry.rectclip_s} rectclip\" " \
        " -f #{@filename}",
        @options
      )
    end
  end
end
