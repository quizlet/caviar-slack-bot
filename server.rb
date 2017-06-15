require 'rubygems'
require 'twilio-ruby'
require 'sinatra'
require 'net/http'
require 'uri'
require 'json'
require File.expand_path('../lib/services/slack', __FILE__)

class Server < Sinatra::Application

  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    end

    def slack_url
      @slack_url ||= ENV["SLACK_URL"]
    end

    def slack_client
      @slack_client ||= SlackClient.new(slack_url: slack_url, base_url: base_url)
    end
  end

  get '/' do
    puts "Heartbeat 200 OK"
    "OK"
  end

  post '/text' do
    to = params[:text].split.first
    message = params[:text].split(' ').drop(1).join(' ')

    puts "Attempting to respond to #{to} with \"#{message}\"."

    account_sid = ENV['TWILIO_ACCOUNT_SID']
    auth_token = ENV['TWILIO_AUTH_TOKEN']
    @client = Twilio::REST::Client.new account_sid, auth_token
    @client.account.messages.create(
      from: "#{ENV['TWILIO_PHONE_NUMBER']}",
      to: to,
      body: message
    )

    slack_client.message("Responded to #{to} with \"#{message}\".")
  end

  post '/sms' do
    puts "Received Twilio SMS: #{params.to_s}"

    slack_client.alert("Message from Caviar driver: \"#{params[:Body]}\" - Respond to this text using `/caviar #{params[:From]} <MESSAGE>`.")
  end

  post '/voice' do
    puts "Received Twilio Voice: #{params.to_s}"

    response = Twilio::TwiML::Response.new { |r|
      r.Say "Hello, Caviar driver. I am an automated answering system, but someone will call you back at this number shortly. You can also send text messages to this phone number and someone will read them."
    }.text

    slack_client.alert("The Caviar driver called the contact number. You can send them a text by using `/caviar #{params[:From]} <MESSAGE>`.")

    response
  end
end
