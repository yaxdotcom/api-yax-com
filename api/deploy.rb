require 'rubygems'
require 'github_api'
require 'json'
require 'logger'
require 'nokogiri'
require 'open-uri'

Handler = Proc.new do |req, res|
 
    log = Logger.new(STDOUT)

    # parameters
    authorization_code = req.query['code']
    params = JSON.parse(Base64.decode64(req.query['state']))
    template = params['templateId']
    repository = params['repository']
    title = params['title']
    description = params['description']

    # diagnostics
    log.info('deploy.rb') { "\n template: " + template + "\n" }
    log.info('deploy.rb') { "\n repository: " + repository + "\n" }
    log.info('deploy.rb') { "\n title: " + title + "\n" }
    log.info('deploy.rb') { "\n description: " + description + "\n" }

    # use Heredocs for a README preamble
    doc_preamble = <<~DOC
    # <%= #{title} %>

    This is the repository for the <%= #{repository} %> website.
    DOC

    # download README file and prepend markdown
    uri_readme = URI("https://raw.githubusercontent.com/yaxdotcom/#{template}/master/README.md")
    doc_readme = (URI.open(uri_readme)).read

    # output
    res.status = 200
    res.body =  doc_preamble + "\n\n" + doc_readme

    # # download, parse and replace HTML index file
    # uri_index = URI("https://raw.githubusercontent.com/yaxdotcom/#{template}/master/index.html")
    # page = Nokogiri::HTML(URI.open(uri_index))
    # page.title = title

    # begin
    #     # get and set access_token using user authorization_code and app credentials
    #     api = Github.new(client_id: ENV['GITHUB_CLIENT_ID'], client_secret: ENV['GITHUB_CLIENT_SECRET'])
    #     access_token = api.get_token(authorization_code)
    #     api.oauth_token = access_token.token
    #     # get username
    #     user = api.users.get
    #     log.info('deploy.rb') { "\n user login: " + user.login + "\n" }
    #     log.info('deploy.rb') { "\n user email: " + user.email + "\n" }
    #     # create a repo
    #     api.repos.create name: repository,
    #         description: description,
    #         private: false,
    #         has_issues: true
    #     # save a template file
    #     api.repos.contents.create user.login, repository, 'index.html',
    #         content: page.to_html,
    #         path: 'index.html',
    #         message: 'Yax: create file from template'
    #     # output
    #     res.status = 301
    #     res['Location'] = "https://github.com/#{user.login}?tab=repositories"
    #     res.body = ''
    # rescue Github::Error::GithubError => e
    #     log.error('deploy.rb') { "\n" + e.message + "\n" }
    #     res.status = 500
    #     if(e.message.include?('name already exists'))
    #         res.body = "Error: A repository with the name #{repository} already exists. Try another name."
    #     else
    #         res.body = e.message
    #     end
    # end

end
