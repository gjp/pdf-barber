module Barber
  module Helpers

    def system_command(command_with_args, params)
      command = command_with_args.split[0]
      puts 'Running: ' + command_with_args if params[:verbose]

      result  = `#{command_with_args}`
      raise BarberError, "command failed" if $?.exitstatus > 0

      result
    end

    def matches_to_i(str, re)
      m = str.match(re).to_a
      m.shift
      m.map(&:to_i)
    end

    def check_page_range(pages, range)
      page_range = (1..pages).to_a
      unless ( page_range & range ).size == 2
       raise BarberError,
         "Page range values must both be within 1-#{pages}"
      end
    end

    def feedback(str)
      puts str if File.basename($PROGRAM_NAME) == 'barber.rb'
    end

    def check_filename(filename)
      raise BarberError,
        "An input filename is required" unless filename
      raise BarberError,
        "Cannot open #{filename}" unless File.readable?(filename)
    end

  end
end
