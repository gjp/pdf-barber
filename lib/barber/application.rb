module Barber
  class BarberError < RuntimeError; end

  class Application
    def self.run(argv)
      params = get_params(argv)
      Shaver.new(params).start

    rescue BarberError => e
      puts "\nBarberError: #{e.message}"
    end

    def self.get_params(argv)
      params = {}

      params[:filenames] = OptionParser.new do |parser|
        parser.banner = "Usage: #{$PROGRAM_NAME} [options] FILE"

        parser.on("-r", "--range RANGE", "Page range separated by a hyphen, e.g. 2-51") do |r|
          params[:range] = r.split('-').map(&:to_i)
        end

        parser.on("-m", "--method METHOD", "Composition method") do |m|
          params[:method] = m
        end

        parser.on("-d", "--dir DIR", "Temporary directory (keeps working files)") do |d|
          params[:tmpdir] = d
        end

        parser.on("-v", "--verbose", "Run verbosely") do |v|
          params[:verbose] = v
        end

      end.parse(argv)

      params
    end
  end
end
