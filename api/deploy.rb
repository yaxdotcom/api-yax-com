require 'rubygems'
require 'fauna'
require 'github_api'
require 'http'
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
    log.info('deploy.rb') { "\n template: " + template + "\n" } if !template.nil?
    log.info('deploy.rb') { "\n repository: " + repository + "\n" } if !repository.nil?
    log.info('deploy.rb') { "\n title: " + title + "\n" } if !title.nil?
    log.info('deploy.rb') { "\n description: " + description + "\n" } if !description.nil?

    # download and parse a configuration file
    uri_yaml = "https://raw.githubusercontent.com/yaxdotcom/#{template}/master/yax.yaml"
    manifest = YAML.parse(URI.parse(uri_yaml).open.read).to_ruby

    # method to extract filenames from a manifest file
    def extract_filenames(source, filepath, filelist)
        case source.class.to_s
        when 'String'
            filelist << filepath + source
            filepath = ''
        when 'Array'
            source.each do |item|
                extract_filenames(item, filepath, filelist)
            end
        when 'Hash'
            source.each do |key, value|
                filepath << key + '/'
                extract_filenames(value, filepath, filelist)
            end
        end
        filelist
    end

    # get a list of filenames from manifest file
    filelist = extract_filenames(manifest['files'], '', [])

    # use Heredocs for a README preamble
    def doc_preamble(user, params)
        doc_preamble = <<~DOC
        # #{params['title']}

        This is the GitHub repository for the project "#{params['repository']}." It was generated from a
        website template at [yax.com](https://yax.com).

        With GitHub, storage is permanent (and free). From GitHub, you can deploy your website for free hosting.
        Just click a button to deploy your website to [Render.com](https://render.com/),
        [Vercel](https://vercel.com/), or [Netlify](https://www.netlify.com/).

        [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

        [![Deploy to Vercel](https://vercel.com/button)](https://vercel.com/import/project?template=https://github.com/#{user.login}/#{params['repository']})

        [![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/#{user.login}/#{params['repository']})

        After deploying your website, visit your site to edit the pages.

        Visit [tutorials.yax.com](https://tutorials.yax.com/) for more information.

        Read below about the website template.
        DOC
    end

    begin
        # get and set access_token using user authorization_code and app credentials
        api = Github.new(client_id: ENV['GITHUB_CLIENT_ID'], client_secret: ENV['GITHUB_CLIENT_SECRET'], scopes: ['public_repo'])
        access_token = api.get_token(authorization_code)
        api.oauth_token = access_token.token
        # get username
        user = api.users.get
        log.info('deploy.rb') { "\n user login: " + user.login + "\n" } if !user.login.nil?
        # create a repo
        api.repos.create name: repository,
            description: 'Description: ' + description,
            private: false,
            has_issues: true
        # retrieve and save files
        uri_raw = 'https://raw.githubusercontent.com/yaxdotcom/'
        uri_repo = "https://github.com/#{user.login}/#{repository}/data"
        filelist.each do |filename|
            commit_msg = "Yax: #{File.basename(filename)} from template"
            case
            when filename == 'README.md'
                # download, add a preamble, and save a README file
                uri_readme = URI("#{uri_raw}#{template}/master/#{filename}")
                doc_readme = doc_preamble(user, params) + "\n" + (URI.open(uri_readme)).read
                api.repos.contents.create user.login, repository, filename,
                    content: doc_readme,
                    path: filename,
                    message: commit_msg
            when filename == 'index.html'
                # download, replace some tags, and save an index.html file
                uri_page = URI("#{uri_raw}#{template}/master/#{filename}")
                page = Nokogiri::HTML(URI.open(uri_page))
                page.title = title
                page.at('meta[name="description"]')['content'] = description
                page.at_css('body').attributes['mv-storage'].value = uri_repo
                page.at_css('h1#headline').content = title
                page.at_css('p#description').content = description
                api.repos.contents.create user.login, repository, filename,
                    content: page.to_html,
                    path: filename,
                    message: commit_msg
            when filename.end_with?('.html')
                # download, replace some tags, and save an HTML file
                uri_page = URI("#{uri_raw}#{template}/master/#{filename}")
                page = Nokogiri::HTML(URI.open(uri_page))
                page.title = title + ' | ' + File.basename(filename, '.html').capitalize
                page.at('meta[name="description"]')['content'] = description
                page.at_css('body').attributes['mv-storage'].value = uri_repo
                api.repos.contents.create user.login, repository, filename,
                    content: page.to_html,
                    path: filename,
                    message: commit_msg
            else
                # download and save a file without modification
                uri_file = URI("#{uri_raw}#{template}/master/#{filename}")
                file = (URI.open(uri_file)).read
                api.repos.contents.create user.login, repository, filename,
                    content: file,
                    path: filename,
                    message: commit_msg
            end
        end

        # send deploy data to FaunaDB
        fauna = Fauna::Client.new( secret: ENV['FAUNA_SERVER_KEY'] )
        fauna.query do
            create ref('classes/deploys'), data: {
                user_login: user.login,
                url: "https://github.com/#{user.login}/#{repository}",
                template: template,
                repository: repository,
                title: title,
                description: description
                }
        end

        # send email alert via Sendinblue
        payload = '{'
        payload << '"sender":{"name":"Yax","email":"support@yax.com"},'
        payload << '"to":[{"email":"daniel@danielkehoe.com","name":"Daniel Kehoe"}],'
        payload << '"subject":"Try Yax: ' + user.login + '",'
        payload << '"htmlContent":"<html><head></head><body><ul><li>user: ' + user.login
        payload << '</li><li>template: ' + template
        payload << '</li><li>repository: ' + repository
        payload << '</li><li>title: ' + title
        payload << '</li><li>description: ' + description
        payload << '</li></ul></body></html>"'
        payload << '}'
        response = HTTP.headers(
          'accept': 'application/json',
          'content-type': 'application/json',
          'api-key': ENV['SENDINBLUE_API_KEY']
        ).post("https://api.sendinblue.com/v3/smtp/email", :json => JSON.parse(payload) )

        # output
        res.status = 301
        res['Location'] = "https://github.com/#{user.login}/#{repository}"
        res.body = ''
    rescue Github::Error::GithubError => e
        log.error('deploy.rb') { "\n" + e.message + "\n" }
        res.status = 500
        if(e.message.include?('name already exists'))
            res.body = "Error: A repository with the name #{repository} already exists. Try another name."
        else
            res.body = e.message
        end
    end

end
