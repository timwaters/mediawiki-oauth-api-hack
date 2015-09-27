require "net/https"
require "uri"
require 'json'


site = "https://commons.wikimedia.org"
        
 title = "Senate_Atlas%2C_1870%E2%80%931907._Sheet_XXI-XXII_12-13_Ahlainen.jpg"
 title = URI.decode title
# 
# title2 = 'Karte_von_Ober%C3%B6sterreich_(Vischer,_1667).jpg'
# title2 = URI.decode title2
# 
# uri = "#{site}/w/api.php?action=query&prop=info&format=json&titles=File:#{title}|File:#{title2}"
#title = "1658_1700_Ara_biae_Schenk_%26_Valk_Janssonius.JPG"
#title = URI.decode title

uri = "#{site}/w/api.php?action=query&prop=imageinfo|info&iiprop=url&format=json&titles=File:#{title}"

puts uri.inspect

url = URI.parse(URI.encode(uri))

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

req = Net::HTTP::Get.new(URI.encode(uri))
req.add_field('User-Agent', 'WikiMaps Warper Update PageID Script by Chippyy chippy2005@gmail.com')

resp = http.request(req)
puts resp.body
body = JSON.parse(resp.body)

puts body.inspect
