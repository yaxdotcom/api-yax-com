require 'rubygems'
require 'github_api'
require 'json'
require 'logger'
require 'nokogiri'
require 'open-uri'
require 'yaml'

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

    # download and parse a configuration file
    uri_yaml = URI("https://raw.githubusercontent.com/yaxdotcom/#{template}/master/yax.yaml")
    config = YAML.parse((URI.open(uri_yaml)).read)
    log.info('deploy.rb') { "\n config: " + config.inspect + "\n" }

    # output
    res.status = 200
    res.body = config

    # # download README file
    # uri_readme = URI("https://raw.githubusercontent.com/yaxdotcom/#{template}/master/README.md")
    # doc_readme = (URI.open(uri_readme)).read

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

    #     # use Heredocs for a README preamble
    #     doc_preamble = <<~DOC
    #     # #{title}

    #     This is the GitHub repository for your #{repository} project, generated from a 
    #     [yax.com](https://yax.com) website template. We save your files to GitHub because 
    #     storage is permanent (and free) and you get version control to track changes to 
    #     your files. Plus, using GitHub, you can easily deploy your website for free hosting.
    #     Click a button below to deploy your website.

    #     [![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/#{user.login}/#{repository})

    #     [![Deploy to Vercel](https://vercel.com/button)](https://vercel.com/import/project?template=https://github.com/#{user.login}/#{repository})

    #     After you've deployed your website, visit your site to edit the pages. The template 
    #     includes the [Mavo](https://mavo.io/) website editor so you can edit content right 
    #     on the website.

    #     You can read below about the #{template} website template you've chosen.
    #     DOC

    #     # create a repo
    #     api.repos.create name: repository,
    #         description: 'Built by yax.com: ' + description
    #         private: false,
    #         has_issues: true
    #     # save a README file
    #     api.repos.contents.create user.login, repository, 'README.md',
    #         content: doc_preamble + "\n" + doc_readme,
    #         path: 'README.md',
    #         message: 'Yax: README from template'
    #     # save a template file
    #     api.repos.contents.create user.login, repository, 'index.html',
    #         content: page.to_html,
    #         path: 'index.html',
    #         message: 'Yax: index.html file from template'
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
