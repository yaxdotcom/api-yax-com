require 'rubygems'
require 'logger'
require 'github_api'
require 'nokogiri'
require 'open-uri'

Handler = Proc.new do |req, res|
 
    log = Logger.new(STDOUT)

    # variables
    project = 'my_vercel_website'
    title = 'My Website Deployed on Vercel'
    # parse and replace
    uri = URI('https://raw.githubusercontent.com/yaxdotcom/yax-template-wip/master/index.html')
    page = Nokogiri::HTML(URI.open(uri))
    page.title = title

    api = Github.new
    api.oauth_token = ENV['OAUTH_TOKEN']
    begin
        # create a repo
        api.repos.create name: project,
            description: title,
            private: false,
            has_issues: true
        # save a template file
        api.repos.contents.create 'DanielKehoe', project, 'index.html',
            content: page.to_html,
            path: 'index.html',
            message: 'create file from template'
    rescue Github::Error::GithubError => e
        log.error('nokogiri.rb') { "\n" + e.message = "\n" }
    end

    # output
    res.status = 301
    res['Location'] = 'https://github.com/DanielKehoe?tab=repositories'
    res.body = ''
end
