require 'net/ssh'

class EdgeRouter
  CMD_WRAPPER = "/opt/vyatta/bin/vyatta-op-cmd-wrapper"

  attr_reader :ssh
  attr_reader :host
  attr_reader :user
  attr_reader :password

  def initialize(host, user, password)
    @host = host
    @user = user
    @password = password

    @ssh = Net::SSH.start(host, user, password: password)
  end

  def exec(command)
    ssh.exec!("%s %s" % [CMD_WRAPPER, command]).strip
  end

  def show_load_balance_status
    response = exec("show load-balance status")
    Parser.show_load_balance_status(response)
  end

  module Parser
    def self.show_load_balance_status(text)
      tree = {}
      group = nil
      interface = nil
      flows = nil
      text.each_line do |line|
        if matches = line.match(/^Group (\w+)/)
          group_name = matches[1]
          group = tree[group_name] = {}
          interface = nil
          flows = nil
        elsif group && matches = line.match(/^\s+interface\s+:\s(\w+)/)
          interface_name = matches[1]
          interface = group[interface_name] = {}
          flows = nil
        elsif interface && matches = line.match(/^\s+flows/)
          flows = interface["flows"] = {}
        elsif interface && matches = line.match(/^\s+([\w ]+\w)\s+:\s+([^\s]+)/)
          name = matches[1]
          value = matches[2]
          if flows
            flows[name] = value
          else
            interface[name] = value
          end
        end
      end
      tree
    end
  end
end
