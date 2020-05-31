require 'rubygems'
require 'github_api'
require 'nokogiri'
require 'open-uri'

Handler = Proc.new do |req, res|
    # variables
    project = 'my_new_website'
    title = 'Deployed on Vercel'
    # parse and replace
    uri = URI('https://raw.githubusercontent.com/yaxdotcom/yax-template-wip/master/index.html')
    page = Nokogiri::HTML(URI.open(uri))
    page.title = title
    # output
    res.status = 301
    res['Location'] = 'https://github.com/DanielKehoe?tab=repositories'
    res.body = ''
end
