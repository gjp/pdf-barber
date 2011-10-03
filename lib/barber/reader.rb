module Barber
  class Reader
    include Helpers

    attr_reader :num_pages, :mediabox, :cropbox

    def initialize(params)
      @params = params
      check_filename(params[:filename])
    end

    def read
      pdf_info = system_command(
        "gs"\
        " -q"\
        " -dNODISPLAY"\
        " -dWhichPage=#{@params[:range][0]}"\
        " -sFile=#{@params[:filename]}"\
        " lib/barber/pdf_geometry.ps",
        @params
      )

      num_pages, mediabox, cropbox = pdf_info.split(',')

      num_re = '\s+([\d\.\-]+)'
      @num_pages = matches_to_i( num_pages, /Pages:#{num_re}/ )[0]
      @mediabox  = matches_to_i( mediabox, /MediaBox:#{num_re * 4}/ )
      @cropbox   = matches_to_i( cropbox, /CropBox:#{num_re * 4}/ )

      check_page_range(@num_pages, @params[:range])
      self
    end

    def show_original_boxes
      feedback(
        "MediaBox: #{@mediabox} CropBox: #{@cropbox}"
      )
    end 

    private

    def check_filename(filename)
      raise BarberError,
        "An input filename is required" unless filename
      raise BarberError,
        "Cannot open #{filename}" unless File.readable?(filename)
    end

    def check_page_range(pages, range)
      page_range = (1..pages).to_a
      unless ( page_range & range ).size == 2
        raise BarberError,
          "Page range values must both be within 1-#{pages}"
      end
    end

  end
end
