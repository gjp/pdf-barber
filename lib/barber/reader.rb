module Barber
  class Reader

    def initialize(params)
      @params = params
      check_filename
    end

    def check_filename
      filename = @params[:filenames][0]
      raise BarberError, "An input filename is required" unless filename
      raise BarberError, "Cannot open #{filename}" unless File.readable?(filename)
      @params[:filename] = @params[:filenames][0]
    end

    def read
      # May need to expand this to gather box data for all pages.
      # Some PDFs apparently use the TrimBox for per-page masking? Just a guess.

      g = Geometry.new

      pdfinfo = Utils.system_command( "pdfinfo -box #{@params[:filename]}", @params )

      num_re = '\s+([\d\.]+)'

      g.pages    = Utils.matches_to_i( pdfinfo, /Pages:#{num_re}/ )
      g.pagesize = Utils.matches_to_i( pdfinfo, /Page size:#{num_re} x#{num_re}/ )
      g.mediabox = Utils.matches_to_i( pdfinfo, /MediaBox:#{num_re * 4}/ )
      g.cropbox  = Utils.matches_to_i( pdfinfo, /CropBox:#{num_re * 4}/ )
      g
    end
  end
end
