
Gem::Specification.new do |s|
  s.name          = 'compound'
  s.version       = '0.0.3'
  s.date          = '2014-01-31'
  s.summary       = "compound"
  s.description   = "A new paradigm for mixing objects in Ruby."
  s.authors       = ["Joe McIlvain"]
  s.email         = 'joe.eli.mac@gmail.com'
  
  s.files         = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/jemc/compound/'
  s.licenses      = 'MIT License'
  
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-rescue'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'fivemat'
end
