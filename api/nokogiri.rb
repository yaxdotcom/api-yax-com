require 'rubygems'
require 'logger'
require 'github_api'
require 'nokogiri'
require 'open-uri'

Handler = Proc.new do |req, res|
 
    log = Logger.new(STDOUT)
    log.info("writing log message")
    log.info('nokogiri') { "writing second log message" }

    # variables
    project = 'my_new_website'
    title = 'Deployed on Vercel'
    # parse and replace
    uri = URI('https://raw.githubusercontent.com/yaxdotcom/yax-template-wip/master/index.html')
    page = Nokogiri::HTML(URI.open(uri))
    page.title = title

    # api = Github.new
    # api.oauth_token = "TODO"
    # begin
    #     # create a repo
    #     api.repos.create name: project,
    #         description: 'Website for ' + project,
    #         private: false,
    #         has_issues: true
    #     # save a template file
    #     api.repos.contents.create 'DanielKehoe', project, 'index.html',
    #         # content: page.to_html,
    #         content: page.to_html
    #         path: 'index.html',
    #         message: 'create file from template'
    # rescue Github::Error::GithubError => e
    #     log.error(e.message)
    # end



    # output
    res.status = 301
    res['Location'] = 'https://github.com/DanielKehoe?tab=repositories'
    res.body = ''
end
