require 'net/http'
require 'uri'

urls_file = 'tmp/urls'
dest_dir = 'tmp/all'
urls = File.read(urls_file).split("\n")

urls.each do |url|
  extname = /(\.\w+$)/.match(url)[1]
  random_str = rand(2**256).to_s(36).ljust(8,'a')[0..7]
  File.open(dest_dir + '/' + random_str + extname, 'wb') do |f|
    f.write Net::HTTP.get(URI(url))
  end
  puts "#{url} OK"
end
