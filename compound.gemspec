
Gem::Specification.new do |s|
  s.name          = 'compound'
  s.version       = '1.2.2'
  s.date          = '2014-05-06'
  s.summary       = "compound"
  s.description   = "A new paradigm for mixing objects in Ruby."
  s.authors       = ["Joe McIlvain"]
  s.email         = 'joe.eli.mac@gmail.com'
  
  s.files         = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/jemc/compound/'
  s.licenses      = 'MIT License'
  
  s.add_development_dependency 'bundler',    '~>  1.6'
  s.add_development_dependency 'rake',       '~> 10.3'
  s.add_development_dependency 'pry',        '~>  0.9'
  s.add_development_dependency 'pry-rescue', '~>  1.4'
  s.add_development_dependency 'rspec',      '~>  3.0'
  s.add_development_dependency 'rspec-its',  '~>  1.0'
  s.add_development_dependency 'fivemat',    '~>  1.3'
  s.add_development_dependency 'yard',       '~>  0.8'
end
