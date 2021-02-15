require 'rubygems'
require 'fauna'
require 'github_api'
require 'http'
require 'json'
require 'logger'
require 'nokogiri'
require 'open-uri'
require 'simple_segment'
require 'yaml'

Handler = Proc.new do |req, res|

    log = Logger.new(STDOUT)

    analytics ||= SimpleSegment::Client.new(
      write_key: ENV['SEGMENT_WRITE_KEY'],
      on_error: proc { |error_code, error_body, exception, response| }
    )
    
    # parameters
    authorization_code = req.query['code']
    params = JSON.parse(Base64.decode64(req.query['state']))
    template = params['templateId']
    repository = params['repository'].gsub(/(\W)/, "-")
    title = params['title']
    description = params['description']

    # diagnostics
    log.info { " template: " + template + "\n" } if !template.nil?
    log.info { " repository: " + repository + "\n" } if !repository.nil?
    log.info { " title: " + title + "\n" } if !title.nil?
    log.info { " description: " + description + "\n" } if !description.nil?
    log.info { " ip address: " + req.header['x-forwarded-for'].first() + "\n" } if !req.header['x-forwarded-for'].nil?

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
    def doc_preamble(title, user, repository, template)
        doc_preamble = <<~DOC
        # Project: #{title}

        This is the GitHub repository for the project you named "#{repository}", generated from the "#{template}" website template at [yax.com](https://yax.com).

        From here, deploy your website for free hosting. Just click a button to deploy your website to [Netlify](https://www.netlify.com/), [Vercel](https://vercel.com/), or [Render.com](https://render.com/). During the process, you will create a second repo for deployment. Name it what you like; I suggest "#{repository}-deploy".

        [![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/#{user.login}/#{repository})

        [![Deploy to Vercel](https://vercel.com/button)](https://vercel.com/import/project?template=https://github.com/#{user.login}/#{repository})

        [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)
        
       For help, open a GitHub issue and mention [DanielKehoe](https://github.com/DanielKehoe) or email [support@yax.com](mailto:support@yax.com?subject=[GitHub]%20#{repository}).
        
       ## Stackless newsletter
       
       It is early days for Yax. If you are curious about what we are doing, go to [stackless.community](https://stackless.community/) and sign up for the newsletter, all about Yax and building websites without frameworks or build tools.
       

        DOC
    end

    # use Heredocs for a GitHub issue
    def issue_body
        issue_body = <<~DOC
        @DanielKehoe would like feedback about yax.com.
        
        Did deployment and editing work?
        
        What are your thoughts, suggestions for improvements, etc.?
        
        Just give a reply here.
        
        _If you are curious about Yax, go to [stackless.community](https://stackless.community/) and sign up for the newsletter, all about Yax and building websites without frameworks or build tools._
        
        DOC
    end


    def any_errors(errors)
        return '' if(errors.nil? || errors.empty?)
        msg = "### Errors\n\n#{errors}\n"
    end

    begin
        # get and set access_token using user authorization_code and app credentials
        api = Github.new(client_id: ENV['GITHUB_CLIENT_ID'], client_secret: ENV['GITHUB_CLIENT_SECRET'], scopes: ['public_repo'])
        access_token = api.get_token(authorization_code)
        api.oauth_token = access_token.token
        # get username
        user = api.users.get
        log.info { "\n user login: " + user.login + "\n" } if !user.login.nil?
        # create a repo
        api.repos.create name: repository,
            description: 'Description: ' + description,
            private: false,
            has_issues: true
        # retrieve and save files
        errors = ''
        uri_raw = 'https://raw.githubusercontent.com/yaxdotcom/'
        uri_repo = "https://github.com/#{user.login}/#{repository}/blob/main/data"
        filelist.each do |filename|
            commit_msg = "(yax) #{File.basename(filename)} from template"
            case
            when filename == 'index.html'
                # download, replace some tags, and save an index.html file
                uri_page = URI("#{uri_raw}#{template}/master/#{filename}")
                begin
                    page = Nokogiri::HTML(URI.open(uri_page))
                    page.title = title if page.title
                    page.at('meta[name="description"]')['content'] = description if page.at('meta[name="description"]')['content']
                    page.at_css('body').attributes['mv-storage'].value = uri_repo if page.at_css('body').attributes['mv-storage']
                    page.at_css('body').attributes['mv-app'].value = repository if page.at_css('body').attributes['mv-app']
                    page.at_css('[id="title"]').content = title if page.at_css('[id="title"]')
                    page.at_css('[id="description"]').content = description if page.at_css('[id="description"]')
                    api.repos.contents.create user.login, repository, filename,
                        content: page.to_html,
                        path: filename,
                        message: commit_msg
                rescue StandardError => e
                    msg = "Was there a yax.yaml file error? #{e.inspect} #{filename}\n"
                    errors << msg + "\n"
                    puts msg
                end
            when filename.end_with?('.html')
                # download, replace some tags, and save an HTML file
                uri_page = URI("#{uri_raw}#{template}/master/#{filename}")
                begin
                    page = Nokogiri::HTML(URI.open(uri_page))
                    page.title = title + ' | ' + File.basename(filename, '.html').capitalize if page.title
                    page.at('meta[name="description"]')['content'] = description if page.at('meta[name="description"]')['content']
                    page.at_css('body').attributes['mv-storage'].value = uri_repo if page.at_css('body').attributes['mv-storage']
                    page.at_css('body').attributes['mv-app'].value = repository if page.at_css('body').attributes['mv-app']
                    api.repos.contents.create user.login, repository, filename,
                        content: page.to_html,
                        path: filename,
                        message: commit_msg
                rescue StandardError => e
                    msg = "Was there a yax.yaml file error? #{e.inspect} #{filename}\n"
                    errors << msg + "\n"
                    puts msg
                end
            else
                unless(filename == 'README.md')
                    # download and save a file without modification
                    uri_file = URI("#{uri_raw}#{template}/master/#{filename}")
                    begin
                        file = (URI.open(uri_file)).read
                        api.repos.contents.create user.login, repository, filename,
                            content: file,
                            path: filename,
                            message: commit_msg
                    rescue StandardError => e
                        msg = "Was there a yax.yaml file error? #{e.inspect} #{filename}\n"
                        errors << msg + "\n"
                        puts msg
                    end
                end
            end
        end

        # download, add a preamble, and save a README file
        filename = 'README.md'
        uri_readme = URI("#{uri_raw}#{template}/master/#{filename}")
        commit_msg = "(yax) #{File.basename(filename)} from template"
        begin
            doc_readme = doc_preamble(title, user, repository, template) + "\n" + any_errors(errors) + (URI.open(uri_readme)).read
            api.repos.contents.create user.login, repository, filename,
                content: doc_readme,
                path: filename,
                message: commit_msg
        rescue StandardError => e
            puts "error writing README: #{e.inspect}\n"
        end

        # open an issue in the GitHub repo
        begin
            api.issues.create user: user.login, repo: repository, title: "Yax is new... feedback, please?", body: issue_body
        rescue StandardError => e
            puts "error writing GitHub issue: #{e.inspect}\n"
        end

        # send event to Segment.com analytics
        begin
            analytics.identify(user_id: user.login)
            analytics.track(
                user_id: user.login,
                event: 'Template Deployed',
                properties: {
                  template: template,
                  url: "https://github.com/#{user.login}/#{repository}"},
                  context: { 
                      ip: "#{req.header['x-forwarded-for'].first() if !req.header['x-forwarded-for'].nil?}"
            })
        rescue StandardError => e
            puts "error sending event to Segment.com: #{e.inspect}\n"
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
        
        # add activity to Orbit CRM
        payload_orbit_1 = '{'
        payload_orbit_1 << '"description": "using template **' + template + '** with title **' + title + '** and description **' + description + '**",'
        payload_orbit_1 << '"link": "https://github.com/' + user.login + '/' + repository + '",'
        payload_orbit_1 << '"link_text": "' + repository + '",'
        payload_orbit_1 << '"title": "Try Yax",'
        payload_orbit_1 << '"activity_type": "Try Yax",'
        payload_orbit_1 << '"identity": {
            "source": "github",
            "username": "' + user.login + '"
          }'
        payload_orbit_1 << '}'
        response = HTTP.auth("Bearer #{ENV['ORBIT_API_KEY']}").post("https://app.orbit.love/api/v1/508/activities", :json => JSON.parse(payload_orbit_1) )
        
        # add tag to Orbit CRM
        payload_orbit_2 = '{'
        payload_orbit_2 << '"identity": {
            "source": "github",
            "username": "' + user.login + '"
          },'
        payload_orbit_2 << '"tags_to_add": "try-yax"'
        payload_orbit_2 << '}'
        response = HTTP.auth("Bearer #{ENV['ORBIT_API_KEY']}").post("https://app.orbit.love/api/v1/508/members", :json => JSON.parse(payload_orbit_2) )

        # send email alert via Sendinblue
        payload = '{'
        payload << '"sender":{"name":"Yax API","email":"support@yax.com"},'
        payload << '"to":[{"email":"try@yax.com","name":"Yax Support"}],'
        payload << '"subject":"Try Yax: ' + user.login + '",'
        payload << '"htmlContent":"<html><head></head><body><ul><li>user: ' + user.login
        payload << '</li><li>template: ' + template
        payload << '</li><li>repository: ' + repository
        payload << '</li><li>title: ' + title
        payload << '</li><li>description: ' + description
        payload << '</li><li>url: ' + "https://github.com/#{user.login}/#{repository}"
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
