require 'rubygems'
require 'logger'
require 'github_api'
require 'nokogiri'
require 'open-uri'

Handler = Proc.new do |req, res|
 
    log = Logger.new(STDOUT)

    # parameters
    template = req.query['templateId']
    account = req.query['github-account']
    repository = req.query['repository']
    title = req.query['title']
    description = req.query['description']

    log.info('deploy.rb') { "\n template: " + template + "\n" }
    log.info('deploy.rb') { "\n account: " + account + "\n" }
    log.info('deploy.rb') { "\n repository: " + repository + "\n" }
    log.info('deploy.rb') { "\n title: " + title + "\n" }
    log.info('deploy.rb') { "\n description: " + description + "\n" }

    # parse and replace
    uri = URI("https://raw.githubusercontent.com/yaxdotcom/#{template}/master/index.html")
    page = Nokogiri::HTML(URI.open(uri))
    page.title = title

    api = Github.new
    api.oauth_token = ENV['OAUTH_TOKEN']
    begin
        # create a repo
        api.repos.create name: repository,
            description: description,
            private: false,
            has_issues: true
        # save a template file
        api.repos.contents.create account, repository, 'index.html',
            content: page.to_html,
            path: 'index.html',
            message: 'create file from template'
    rescue Github::Error::GithubError => e
        log.error('nokogiri.rb') { "\n" + e.message = "\n" }
    end

    # output
    res.status = 301
    res['Location'] = "https://github.com/#{account}?tab=repositories"
    res.body = ''

    # res.status = 200
    # res.body = 'processed'
end
