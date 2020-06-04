require 'rubygems'
require 'github_api'
require 'json'
require 'logger'
require 'nokogiri'
require 'open-uri'

Handler = Proc.new do |req, res|
 
    log = Logger.new(STDOUT)

    session_code = req.query['code']
    params = JSON.parse(Base64.decode64(req.query['state']))

    # parameters
    template = params['templateId']
    account = 'DanielKehoe'
    repository = params['repository']
    title = params['title']
    description = params['description']

    log.info('deploy.rb') { "\n template: " + template + "\n" }
    log.info('deploy.rb') { "\n account: " + account + "\n" }
    log.info('deploy.rb') { "\n repository: " + repository + "\n" }
    log.info('deploy.rb') { "\n title: " + title + "\n" }
    log.info('deploy.rb') { "\n description: " + description + "\n" }

    # # parse and replace
    # uri = URI("https://raw.githubusercontent.com/yaxdotcom/#{template}/master/index.html")
    # page = Nokogiri::HTML(URI.open(uri))
    # page.title = title

    # api = Github.new
    # api.oauth_token = ENV['OAUTH_TOKEN']
    # begin
    #     # create a repo
    #     api.repos.create name: repository,
    #         description: description,
    #         private: false,
    #         has_issues: true
    #     # save a template file
    #     api.repos.contents.create account, repository, 'index.html',
    #         content: page.to_html,
    #         path: 'index.html',
    #         message: 'create file from template'
    # rescue Github::Error::GithubError => e
    #     log.error('nokogiri.rb') { "\n" + e.message = "\n" }
    # end

    # # output
    # res.status = 301
    # res['Location'] = "https://github.com/#{account}?tab=repositories"
    # res.body = ''

    res.status = 200
    res.body = 'processed'
end