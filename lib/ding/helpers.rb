module Ding
  module Helpers
    # NOTE: only for commands where we are interested in the effect
    # as unless verbose is turned on, stdout and stderr are suppressed
    def run_cmd(cmd)
      if self.options[:verbose]
        puts "$ #{cmd}"
      else
        cmd << ' &>/dev/null '
      end
      system cmd
    end
  end
end
