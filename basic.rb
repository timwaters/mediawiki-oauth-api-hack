require 'rubygems'
require 'oauth'
require 'yaml'

# Basic oauth interactions with mediawiki oauth api 
# Usage
# KEY=foo SECRET=bar ruby basic.rb
#
#any problems and delete auth.yaml file and try again
#note mediawiki oauth works for localhost only until approved.

@consumer = OAuth::Consumer.new ENV["KEY"], ENV["SECRET"],
                    {:site=>"http://commons.wikimedia.beta.wmflabs.org", 
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

uri = 'http://commons.wikimedia.beta.wmflabs.org/w/api.php?action=query&meta=userinfo&uiprop=rights|editcount&format=json'
resp = @access_token.get(URI.encode(uri))
puts resp.body.inspect
# {"query":{"userinfo":{"id":12345,"name":"WikiUser",
# "rights":["read","writeapi","purge","autoconfirmed","editsemiprotected","skipcaptcha"],
# "editcount":2323}}}