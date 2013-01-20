require 'net/http'
require 'uri'

urls_file = 'tmp/urls'
dest_dir = 'tmp/all'
urls = File.read(urls_file).split("\n")

urls.each do |url|
  extname = /(\.\w+$)/.match(url)[1]
  File.open(dest_dir + '/' + urls.index(url).to_s + extname, 'wb') do |f|
    f.write Net::HTTP.get(URI(url))
  end
  puts "#{url} OK"
end
