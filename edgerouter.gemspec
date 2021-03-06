Gem::Specification.new do |s|
  s.name        = 'edgerouter'
  s.version     = '0.1'
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = 'EdgeRouter via SSH from Ruby'
  s.license     = 'BSD-3-Clause'
  s.description = 'Library for accessing Ubiquiti EdgeRouter via SSH from Ruby'
  s.authors     = [
    'Jeremy Cole',
  ]
  s.email       = 'jeremy@jcole.us'
  s.homepage    = 'https://github.com/jeremycole/edgerouter'
  s.files = [
    'LICENSE',
    'lib/edgerouter.rb',
  ]
  s.add_dependency('net-ssh', '~> 0')
end
