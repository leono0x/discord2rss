
require 'net/http'
require 'uri'
require('rss')
require 'json'
require 'csv'

def getMessages(authToken, server_id, channel_id)
    
    uri = URI.parse("https://discord.com/api/v9/channels/#{channel_id}/messages?limit=50")
    request = Net::HTTP::Get.new(uri)
    request["Referer"] = "https://discord.com/channels/#{server_id}/#{channel_id}"
    request["Authorization"] = authToken

    # Replacing the Authorization key should be enought.
    # If it's not enought, just copy the request as curl from chrome,
    # convert it here https://jhawthorn.github.io/curl-to-ruby/ 
    # and paste the full list of headers except Referer which depends on the channel_id

    # request["Authorization"] = "OTk3OTQxNDQ2ODQzODQyNjAw.GCE0Zu.ed7VReI7Wxw_e3JJYiB3xY_ENK12xYDhsRn3yY"
    # request["Cookie"] = "__dcfduid=e916e560053911ed99c063c8fa5d1a33; __sdcfduid=e916e561053911ed99c063c8fa5d1a33b2864164b6f28f4b00c521ea3e1cde3d1e65663e6ba2cc1ade1545a89647d4e0; _gcl_au=1.1.1488274035.1657998181; _ga=GA1.2.1291968510.1657998181; _gid=GA1.2.1828061320.1657998181; locale=en-GB; OptanonConsent=isIABGlobal=false&datestamp=Sat+Jul+16+2022+17%3A53%3A58+GMT-0300+(Argentina+Standard+Time)&version=6.33.0&hosts=&landingPath=https%3A%2F%2Fdiscord.com%2F&groups=C0001%3A1%2CC0002%3A1%2CC0003%3A1"
    # request["Authority"] = "discord.com"
    # request["Accept"] = "*/*"
    # request["Accept-Language"] = "en-GB,en;q=0.9"
    # request["Sec-Ch-Ua"] = "\".Not/A)Brand\";v=\"99\", \"Google Chrome\";v=\"103\", \"Chromium\";v=\"103\""
    # request["Sec-Ch-Ua-Mobile"] = "?0"
    # request["Sec-Ch-Ua-Platform"] = "\"macOS\""
    # request["Sec-Fetch-Dest"] = "empty"
    # request["Sec-Fetch-Mode"] = "cors"
    # request["Sec-Fetch-Site"] = "same-origin"
    # request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"
    # request["X-Debug-Options"] = "bugReporterEnabled"
    # request["X-Discord-Locale"] = "en-GB"
    # request["X-Super-Properties"] = "eyJvcyI6Ik1hYyBPUyBYIiwiYnJvd3NlciI6IkNocm9tZSIsImRldmljZSI6IiIsInN5c3RlbV9sb2NhbGUiOiJlbi1HQiIsImJyb3dzZXJfdXNlcl9hZ2VudCI6Ik1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE0XzYpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS8xMDMuMC4wLjAgU2FmYXJpLzUzNy4zNiIsImJyb3dzZXJfdmVyc2lvbiI6IjEwMy4wLjAuMCIsIm9zX3ZlcnNpb24iOiIxMC4xNC42IiwicmVmZXJyZXIiOiIiLCJyZWZlcnJpbmdfZG9tYWluIjoiIiwicmVmZXJyZXJfY3VycmVudCI6IiIsInJlZmVycmluZ19kb21haW5fY3VycmVudCI6IiIsInJlbGVhc2VfY2hhbm5lbCI6InN0YWJsZSIsImNsaWVudF9idWlsZF9udW1iZXIiOjEzNzA5NSwiY2xpZW50X2V2ZW50X3NvdXJjZSI6bnVsbH0="
    
    req_options = {
      use_ssl: uri.scheme == "https",
    }
    
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    return response.body

end


# Read config
configStr = File.read('./config.json')
config = JSON.parse(configStr)
authToken = config["authToken"]

channels = CSV.read(config["channels"], 
    :headers=>true, 
    :converters=> lambda {|f| f ? f.strip : nil})

messages = []
channels.each_with_index do |channel, index|

    server_id = channel[0]
    channel_id = channel[1]
    
    puts "\n\nLoading: \nserver_id: #{server_id} channel_id: #{channel_id}\n...\n\n"
    
    if index > 0
        sleep 5        
    end
    
    # Get messages json
    responseBody = getMessages(authToken, server_id, channel_id)
    
    json = JSON.parse(responseBody)
    if !json.is_a?(Array)
        raise "Server error:" + responseBody
    end

    json.each do |msg|
        msg["server_id"] = server_id
    end

    messages += json
    
end

sorted_messages = messages.sort_by{|x| x[:timestamp]}.reverse

# Create rss
rss = RSS::Maker.make("atom") do |maker|

    maker.channel.author = "Discord"
    maker.channel.updated = Time.now.to_s
    maker.channel.about = "https://discord.com/"
    maker.channel.title = "Discord Messages"
    
    sorted_messages.each do |msg|
        
        server_id = msg["server_id"]
        channel_id = msg["channel_id"]
        
        maker.items.new_item do |item|
            item.link = "https://discord.com/channels/#{server_id}/#{channel_id}/#{msg['id']}"
            item.title = "#{msg['author']['username']}@#{channel_id}"
            item.description = msg['content']
            item.updated = Time.now.to_s
        end
    end 
end

File.write('rss.txt', rss)

