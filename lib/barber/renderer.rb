module Barber
  class Renderer
    include Helpers

    attr_reader :dimensions

    def initialize(params)
      @params = params
    end

    def render
      @dimensions = render_pages
      self
    end

    private

    def render_pages
      # Render a range of pages as low-resolution grayscale PNG files
      # Give some feedback; this can take time if the page range is large

      start_page, end_page = *@params[:range]
      feedback("Rendering pages #{start_page} to #{end_page}...")

      system_command(
        "gs"\
        " -sDEVICE=pnggray"\
        " -r36x36"\
        " -dFirstPage=#{start_page}"\
        " -dLastPage=#{end_page}"\
        " -o #{@params[:tmpdir]}/page_%04d.png"\
        " #{@params[:filename]}",
        @params
      )

      first_page_name = "page_%04d.png" % start_page
      image_dimensions( "#{@params[:tmpdir]}/#{first_page_name}" )
    end

    def image_dimensions(name)
      id = system_command( "identify #{name}", @params )
      matches_to_i( id, /PNG ([\d\.]+)x([\d\.]+)/ )
    end

    def show_dimensions
      feedback( "Render dimensions: #{dimensions}" )
    end

  end
end
