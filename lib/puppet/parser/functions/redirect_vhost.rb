#
# redirect_vhost.rb
#

module Puppet::Parser::Functions
  newfunction(:redirect_vhost, :type => :rvalue, :doc => <<-EOS
    Returns the host_railsapp::nginx::vhost definitions for a list of redirects
    EOS
             ) do |arguments|
    raise(Puppet::ParseError, "redirect_vhost(): Wrong number of arguments given (#{arguments.size} for 1)") if arguments.size < 1

    redirects = arguments[0]
    raise(Puppet::ParseError, "redirect_vhost(): Wrong type given (#{redirects.class})") if redirects.class != Hash

    vhosts = {}
    defaults = { 'passenger_enabled' => false }

    redirects.each do |k,v|
      vhosts[k] = defaults.clone
      if v.class == Hash
        vhosts[k]['vhost_options'] = { 'return' => "301 #{v['destination']}$request_uri" }
        vhosts[k].merge!(v)
        vhosts[k].delete('destination')
      else
        vhosts[k]['server_name'] = k
        vhosts[k]['vhost_options'] = { 'return' => "301 #{v}$request_uri" }
      end
    end

    return vhosts
  end
end
