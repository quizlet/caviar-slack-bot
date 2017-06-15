require 'net/http'

class SlackClient
  attr_reader :base_url, :slack_url

  def initialize(slack_url:, base_url:)
    @slack_url = slack_url
    @base_url = base_url
  end

  def alert(text)
    message("<!here> #{text}")
  end

  def message(text)
    uri = URI(slack_url)
    icon_url = "#{base_url}/logo.jpg"

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path)
    req.body = { text: text, username: "Caviar", icon_url: icon_url }.to_json

    https.request(req)

    puts "Posting message to Slack channel: #{text}"
  end
end
