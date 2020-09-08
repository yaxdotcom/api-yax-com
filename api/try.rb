require 'rubygems'
require 'cowsay'
require 'fauna'
require 'nokogiri'
require 'uri'
require 'net/http'

puts("Cowsay gem version: " + Cowsay::VERSION)
puts("Fauna gem version: " + Fauna::VERSION)
puts("Nokogiri gem version: " + Nokogiri::VERSION)

Handler = Proc.new do |req, res|

  url = URI("https://postman-echo.com/get?foo1=bar1&foo2=bar2")
  https = Net::HTTP.new(url.host, url.port);
  https.use_ssl = true
  request = Net::HTTP::Get.new(url)
  response = https.request(request)

  name = req.query['name'] || 'World'
  res.status = 200
  res['Content-Type'] = 'text/text; charset=utf-8'
  # res.body = Cowsay.say("Hello #{name}", 'cow')
  res.body = response.read_body
end