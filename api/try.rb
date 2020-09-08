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

  payload = JSON.parse('{
    "sender":{
        "name":"Yax",
        "email":"support@yax.com"
    },
    "to":[
        {
          "email":"daniel@danielkehoe.com",
          "name":"Daniel Kehoe"
        }
    ],
    "subject":"test mail from Vercel",
    "htmlContent":"<html><head></head><body><h1>Hello this is a test email from sib</h1></body></html>"
  }')

  response = HTTP.headers(
    'accept': 'application/json',
    'content-type': 'application/json',
    'api-key': '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'
  ).post("https://api.sendinblue.com/v3/smtp/email", :json => payload )


  name = req.query['name'] || 'World'
  res.status = 200
  res['Content-Type'] = 'text/text; charset=utf-8'
  # res.body = Cowsay.say("Hello #{name}", 'cow')
  res.body = response.to_s
end