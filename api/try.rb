require 'rubygems'
require 'cowsay'
require 'fauna'
require 'http'
require 'json'
require 'nokogiri'

puts("Cowsay gem version: " + Cowsay::VERSION)
puts("Fauna gem version: " + Fauna::VERSION)
puts("Nokogiri gem version: " + Nokogiri::VERSION)

Handler = Proc.new do |req, res|

  varies = 'test from Vercel'
  payload = '{'
  payload << '"sender":{"name":"Yax","email":"support@yax.com"},'
  payload << '"to":[{"email":"daniel@danielkehoe.com","name":"Daniel Kehoe"}],'
  payload << '"subject":"Try Yax: ' + varies + '",'
  payload << '"htmlContent":"<html><head></head><body><h1>Hello this is a test email from sib</h1></body></html>"'
  payload << '}'

  response = HTTP.headers(
    'accept': 'application/json',
    'content-type': 'application/json',
    'api-key': ENV['SENDINBLUE_API_KEY']
  ).post("https://api.sendinblue.com/v3/smtp/email", :json => JSON.parse(payload) )

  name = req.query['name'] || 'World'
  res.status = 200
  res['Content-Type'] = 'text/text; charset=utf-8'
  # res.body = Cowsay.say("Hello #{name}", 'cow')
  res.body = response.to_s
end