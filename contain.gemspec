
Gem::Specification.new do |s|
  s.name          = 'contain'
  s.version       = '0.0.1'
  s.date          = '2013-12-15'
  s.summary       = "contain"
  s.description   = "A new paradigm for mixing objects in Ruby."
  s.authors       = ["Joe McIlvain"]
  s.email         = 'joe.eli.mac@gmail.com'
  
  s.files         = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/jemc/contain/'
  s.licenses      = 'MIT License'
  
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-rescue'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'fivemat'
end
