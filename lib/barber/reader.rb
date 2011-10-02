module Barber
  class Reader
    include Helpers

    def initialize(params)
      @params = params
      check_filename(params[:filename])
    end

    def read
      g = Geometry.new

      pdfinfo = system_command(
        "pdfinfo -box -f #{@params[:range][0]} #{@params[:filename]}", @params
      )

      num_re = '\s+([\d\.\-]+)'

      g.pages    = matches_to_i( pdfinfo, /Pages:#{num_re}/ )[0]
      g.pagesize = matches_to_i( pdfinfo, /Page size:#{num_re} x#{num_re}/ )
      g.mediabox = matches_to_i( pdfinfo, /MediaBox:#{num_re * 4}/ )
      g.cropbox  = matches_to_i( pdfinfo, /CropBox:#{num_re * 4}/ )

      check_page_range(g.pages, @params[:range])
      g
    end

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
