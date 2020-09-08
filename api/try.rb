require 'rubygems'
require 'cowsay'
require 'fauna'
require 'http'
require 'nokogiri'
require 'uri'

puts("Cowsay gem version: " + Cowsay::VERSION)
puts("Fauna gem version: " + Fauna::VERSION)
puts("Nokogiri gem version: " + Nokogiri::VERSION)

Handler = Proc.new do |req, res|

  response = HTTP.get('https://postman-echo.com/get?foo1=bar1&foo2=bar2')

  name = req.query['name'] || 'World'
  res.status = 200
  res['Content-Type'] = 'text/text; charset=utf-8'
  # res.body = Cowsay.say("Hello #{name}", 'cow')
  res.body = response.to_s
end