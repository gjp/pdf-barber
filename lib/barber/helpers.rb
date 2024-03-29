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

    def feedback(str)
      puts str if File.basename($PROGRAM_NAME) == 'barber.rb'
    end

  end
end
