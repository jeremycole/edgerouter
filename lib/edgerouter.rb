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

  def shell_command(command)
    ssh.exec!(command).strip
  end

  def vyatta_command(command)
    shell_command("%s %s" % [CMD_WRAPPER, command])
  end

  def show_load_balance_status
    response = vyatta_command("show load-balance status")
    Parser.show_load_balance_status(response)
  end

  def show_interfaces_counters
    response = vyatta_command("show interfaces counters")
    Parser.show_interfaces_counters(response)
  end

  def netstat_interfaces
    response = shell_command("netstat -i")
    puts response
  end

  def netstat_routes
    response = shell_command("netstat -rn")
    puts response
  end

  def netstat_statistics
    response = shell_command("netstat -s")
    puts response
  end

  def ping(interface, destination, count=1, interval=0.2)
    response = shell_command("/bin/ping -c #{count} -i #{interval} -I #{interface} #{destination}")
    puts response
    Parser.ping(response)
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

    def self.show_interfaces_counters(text)
      counters = {}
      text.each_line do |line|
        next if line.match(/^Interface/)
        if matches = line.match(/^(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+/)
          name = matches[1]
          counters[name] = {
            :rx => {
              :packets => matches[2],
              :bytes => matches[3],
            },
            :tx => {
              :packets => matches[4],
              :bytes => matches[5],
            }
          }
        end
      end
      counters
    end

    def self.ping(text)
      ping = {}
      text.each_line do |line|
        if matches = line.match(/^(\d+) packets transmitted, (\d+) received, ([\d\.]+)% packet loss, time ([\d\.]+)ms/)
          ping[:statistics] = {
            tx: matches[1],
            rx: matches[2],
            loss_pct: matches[3],
            time: matches[4],
          }
        elsif matches = line.match(/^rtt min\/avg\/max\/mdev = ([\d\.]+)\/([\d\.]+)\/([\d\.]+)\/([\d\.]+) ms/)
          ping[:rtt] = {
            min: matches[1],
            avg: matches[2],
            max: matches[3],
            mdev: matches[4],
          }
        end
      end
      ping
    end

  end

end
