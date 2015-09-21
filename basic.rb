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

site = "http://commons.wikimedia.beta.wmflabs.org"

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

uri = "#{site}/w/api.php?action=query&meta=userinfo&uiprop=rights|editcount&format=json"
resp = @access_token.get(URI.encode(uri))
body = JSON.parse(resp.body)

# {"query":{"userinfo":{"id":12345,"name":"WikiUser",
# "rights":["read","writeapi","purge","autoconfirmed","editsemiprotected","skipcaptcha"],
# "editcount":2323}}}

# page name for the users user talk page
page = "User talk:" + body["query"]["userinfo"]["name"]

#get the text of the users page
uri = "#{site}/w/api.php?action=query&prop=revisions&rvprop=content&format=json&titles=#{page}"
#uri = "#{site}/w/api.php?action=query&prop=revisions&rvprop=content&format=json&pageids=51031"
resp = @access_token.get(URI.encode(uri))
body = JSON.parse(resp.body)

#
# Get wikitext
#

pageid = body["query"]["pages"].keys.first
revision = body["query"]["pages"][pageid]["revisions"].first 
wikitext = revision["*"]


if wikitext.include? "{{Map"
  # \{\{Map(.*?)\}\}  matches {{Map .... }}
  #\{\{\s*Map(.*?)\}\} matches {{  Map .... }}
#  match for  {{Template:Map}} ?
# \{{2}\s*(Map|Template:map)(.*?)\}{2}
end

#
# see if there is a map template in the wikitext
#

map_match = /\{{2}\s*(Map|Template:map)(.*?)\}{2}/mi.match(wikitext)

if map_match
  map_template = map_match[0]
  #split template by pipe symbols
  map_attrs = map_template.split("|")
  new_attrs = []
  map_attrs.each do | map_attr |
    if map_attr.include? "warped"
      map_attr = "warped=yes\n"
    end
    new_attrs << map_attr
  end
  puts "new attrs"
  puts new_attrs.inspect
  map_template = new_attrs.join("|")
  puts map_template.inspect
  
  wikitext.sub!(/\{{2}\s*Map(.*?)\}{2}/m, map_template)
  puts wikitext.inspect
end

#
# SAVE THE WIKITEXT TO THE PAGE
#

if map_match && true 

  #
  # Next fetch the edit csrf token
  #
  uri = "#{site}/w/api.php?action=query&meta=tokens&type=csrf&format=json"
  resp = @access_token.get(URI.encode(uri))
  body = JSON.parse(resp.body)
  puts body.inspect
  #{"batchcomplete"=>"", "query"=>{"tokens"=>{"csrftoken"=>"foobar"}}}

  token = body["query"]["tokens"]["csrftoken"]

  uri = "#{site}/w/api.php"
  #"pageid" => 51031
  post_body =  { "action" => "edit",
                  "title"=> page,
                  "text" => wikitext,
                  "summary" => "updating map template warped attribute",
                  "watchlist" => "nochange",
                  "bot"=> "true",
                  "nocreate" => "true",
                  "contentmodel" => "wikitext",
                  "token" => token,
                  "format" => "json"
                }
  resp = @access_token.post(URI.encode(uri), post_body)
  puts resp.body.inspect
  # "{\"edit\":{\"result\":\"Success\",\"pageid\":51031,\"title\":\"User talk:Chippyy\",
  # \"contentmodel\":\"wikitext\",\"oldrevid\":78186,\"newrevid\":78206,\"newtimestamp\":\"2015-09-18T14:52:01Z\"}}"
end


# {{Map
#  |title = testing
#  |description= a description
#  |latitude = 1.2/1.3/1.5/2.6
#  |longitude = 1.2/1.3/1.5/2.6
#  |warped = no
# }}


