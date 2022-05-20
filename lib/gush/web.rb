# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/reloader'
require 'pry'

require_relative 'client'

module Gush
  class Web < Sinatra::Base
    configure :development do
      register Sinatra::Reloader
    end

    get '/' do
      @workflows = client.all_workflows.map do |w|
        { workflow: w.to_hash }
      end

      @title = "Workflows"
      erb :workflows
    end

    get '/workflows/:id' do |id|
      wf = client.find_workflow(id)
      @workflow = wf.to_hash
      @title    = @workflow[:name]
      @graph    = Graph.new(wf)

      erb :show
    end

    def client 
      @client ||= Gush::Client.new
    end
  end
end
