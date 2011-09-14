require 'optparse'

module Options
  def get_options
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$PROGRAM_NAME} [options] FILE"

      opts.on("-r", "--range RANGE", "Page range separated by a hyphen, e.g. 2-51") do |r|
        @options[:range] = r
      end

      opts.on("-m", "--method METHOD", "Composition method") do |m|
        @options[:method] = m
      end

      opts.on("-v", "--verbose", "Run verbosely") do |v|
        @options[:verbose] = v
      end

    end.parse!
  end
end

