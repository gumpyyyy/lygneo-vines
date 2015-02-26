require './lib/vines/version'

Gem::Specification.new do |s|
  s.name         = 'lygneo-vines'
  s.version      = Vines::VERSION
  s.summary      = %q[Lygneo-vines is a Vines fork build for lygneo integration.]
  s.description  = %q[Lygneo-vines is a Vines fork build for lygneo integration. DO NOT use it unless you know what you are doing!]

  s.authors      = ['David Graham','Lukas Matt']
  s.email        = ['david@negativecode.com','lukas@zauberstuhl.de']
  s.homepage     = 'https://lygneofoundation.org'
  s.license      = 'MIT'

  s.files        = Dir['[A-Z]*', 'vines.gemspec', '{bin,lib,conf,web}/**/*'] - ['Gemfile.lock']
  s.test_files   = Dir['test/**/*']
  s.executables  = %w[vines]
  s.require_path = 'lib'

  s.add_dependency 'bcrypt', '~> 3.1'
  s.add_dependency 'em-hiredis', '~> 0.1.1'
  s.add_dependency 'eventmachine', '~> 1.0.3'
  s.add_dependency 'http_parser.rb', '~> 0.5.3'
  s.add_dependency 'net-ldap', '~> 0.3.1'
  s.add_dependency 'nokogiri', '>= 1.5.10'

  s.add_development_dependency 'minitest', '~> 5.3'
  s.add_development_dependency 'rake', '~> 10.3'

  s.required_ruby_version = '>= 1.9.3'
end
