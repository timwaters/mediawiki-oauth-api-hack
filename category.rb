require 'rubygems'
require 'oauth'
require 'yaml'
require 'json'

# Basic oauth interactions with mediawiki oauth api 
# Usage
# KEY=foo SECRET=bar ruby basic.rb
#
#any problems and delete auth.yaml file and try again
#note mediawiki oauth works for localhost only until approved.

site = "https://commons.wikimedia.org"

@consumer = OAuth::Consumer.new ENV["KEY"], ENV["SECRET"],
                    {:site=>site, 
                     :authorize_path => '/wiki/Special:Oauth/authorize',
                     :access_token_path => '/w/index.php?title=Special:OAuth/token',
                     :request_token_path => '/w/index.php?title=Special:OAuth/initiate'
                   }
              

unless File.exists? "auth.yaml"
  @request_token = @consumer.get_request_token

  puts "Visit the following URL, log in if you need to, and authorize the app"
  puts @request_token.authorize_url
  puts "When you've authorized that token, enter the verifier code you are assigned:"
  puts "look for the param ?oauth_verifier=foobar and paste in 'foobar'"
  verifier = gets.strip                                                                                                                                                               

  @access_token = @request_token.get_access_token(:oauth_verifier => verifier)  
  auth={}
  auth["token"] = @access_token.token
  auth["token_secret"] = @access_token.secret
   
  File.open('auth.yaml', 'w') {|f| YAML.dump(auth, f)}
 else
  auth = YAML.load(File.open('auth.yaml'))
 end

@access_token = OAuth::AccessToken.new(@consumer, auth['token'], auth['token_secret']) 
puts @access_token.inspect
# get categorys
#http://commons.wikimedia.beta.wmflabs.org/w/api.php?action=query&list=categorymembers&cmtitle=Category:1681_maps&cmtype=file&continue=

category_members = []

category = "1681_maps"
cmlimit = 500  #user max = 5000 and bots can get 5000
uri = "#{site}/w/api.php?action=query&list=categorymembers&cmtype=file&continue=&cmtitle=Category:#{category}&format=json&cmlimit=#{cmlimit}"
puts uri.inspect
resp = @access_token.get(URI.encode(uri))
body = JSON.parse(resp.body)
puts body["continue"]
category_members = body["query"]["categorymembers"]

# get maps within that category

# pagination
puts body["continue"].inspect
 until body["continue"].nil?
   url = uri + "&cmcontinue="+ body["continue"]["cmcontinue"]
   resp = @access_token.get(URI.encode(url))
   body = JSON.parse(resp.body)
   puts body["continue"]
   category_members += body["query"]["categorymembers"]
 end

puts category_members.inspect

