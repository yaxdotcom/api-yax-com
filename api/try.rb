require 'rubygems'
require 'cowsay'
require 'fauna'
require 'github_api'
require 'json'
require 'logger'
require 'nokogiri'
require 'open-uri'
require 'webrick'
require 'yaml'

log = Logger.new(STDOUT)
puts("Cowsay gem version: " + Cowsay::VERSION)
puts("WEBrick gem version: " + WEBrick::VERSION)
puts("JSON gem version: " + JSON::VERSION)
puts("Fauna gem version: " + Fauna::VERSION)
puts("Faraday gem version: " + Faraday::VERSION)

#observer = Fauna::ClientLogger.logger { |log| logger.debug(log) }

$fauna = Fauna::Client.new(secret: ENV['FAUNA_SERVER_KEY'])

class Handler < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    name = req.query['name'] || 'world'

    # log data to FaunaDB
    $fauna.query do
      create ref('classes/deploys'), data: {
        user_login: name,
        url: "https://github.com/dk/template",
        template: 'template',
        repository: 'repository',
        title: 'title',
        description: 'description'
      }
    end

    res.status = 200
    res['Content-Type'] = 'text/text; charset=utf-8'
    res.body = Cowsay.say("Hello #{name}", 'cow')
  end
end

server = WEBrick::HTTPServer.new(:Port => 8000)
server.mount("/", Handler)

['INT', 'TERM'].each {|signal|
  trap(signal) {server.shutdown}
}

server.start()
