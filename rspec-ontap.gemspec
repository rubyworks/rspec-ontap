require_relative 'lib/rspec/ontap/version'

Gem::Specification.new do |s|
  s.name        = 'rspec-ontap'
  s.version     = RSpec::OnTap::VERSION
  s.summary     = 'TAP-Y/J formatters for RSpec'
  s.description = 'RSpec On Tap is a pair of RSpec formatters that report in TAP-Y ' \
                  'or TAP-J, for Tapout to render in any of its formats.'

  s.authors  = ['Trans']
  s.email    = ['transfire@gmail.com']
  s.homepage = 'https://github.com/rubyworks/rspec-ontap'
  s.license  = 'BSD-2-Clause'

  s.metadata = {
    'homepage_uri'      => s.homepage,
    'source_code_uri'   => 'https://github.com/rubyworks/rspec-ontap',
    'bug_tracker_uri'   => 'https://github.com/rubyworks/rspec-ontap/issues',
    'changelog_uri'     => 'https://github.com/rubyworks/rspec-ontap/blob/master/HISTORY.md',
    'documentation_uri' => 'https://rubydoc.info/gems/rspec-ontap'
  }

  s.required_ruby_version = '>= 2.7'

  s.files = Dir[
    'lib/**/*.rb', 'demo/**/*',
    '.yardopts', 'README.md', 'HISTORY.md', 'LICENSE.txt'
  ]
  s.require_paths    = ['lib']
  s.extra_rdoc_files = ['HISTORY.md', 'README.md', 'LICENSE.txt']

  s.add_dependency 'rspec', '>= 3.0', '< 4'
  s.add_dependency 'tapout', '>= 0.5'
  s.add_dependency 'json'

  s.add_development_dependency 'rake', '>= 13'
  s.add_development_dependency 'qed', '>= 2.9'
  s.add_development_dependency 'ae', '>= 1.8'
end
