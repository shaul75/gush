# frozen_string_literal: true

require 'tmpdir'
require 'ruby-graphviz'

module Gush
  class Graph
    attr_reader :workflow, :filename, :path, :start_node, :end_node

    def initialize(workflow, options = {})
      @workflow = workflow
      @filename = options.fetch(:filename, "graph.png")
      @path = options.fetch(:path, Pathname.new(Dir.tmpdir).join(filename))
    end

    def viz
      @graph = GraphViz.new(**graph_options)
      @start_node = add_node('start', shape: 'diamond', fillcolor: '#CFF09E')
      @end_node = add_node('end', shape: 'diamond', fillcolor: '#F56991')

      # First, create nodes for all jobs
      @job_name_to_node_map = {}
      workflow.jobs.each do |job|
        add_job_node(job)
      end

      # Next, link up the jobs with edges
      workflow.jobs.each do |job|
        link_job_edges(job)
      end

      @graph
    end

    def svg
      viz.output(:svg => String)
    end

    def path
      @path.to_s
    end

    private

    def add_node(name, **specific_options)
      @graph.add_node(name, **node_options.merge(specific_options))
    end

    def node_color_for_job(job)
      return 'firebrick' if job.failed?
      return '#01FF70' if job.running?
      return '#2ECC40' if job.finished?
      return 'darkgray' if job.enqueued?

      'black'
    end

    def add_job_node(job)
      @job_name_to_node_map[job.name] = add_node(job.name, label: node_label_for_job(job), color: node_color_for_job(job), href: "/gush/workflows/#{job.workflow_id}/#{job.id}", id: job.id, class: "job-node")
    end

    def link_job_edges(job)
      job_node = @job_name_to_node_map[job.name]

      if job.incoming.empty?
        @graph.add_edges(@start_node, job_node, **edge_options)
      end

      if job.outgoing.empty?
        @graph.add_edges(job_node, @end_node, **edge_options)
      else
        job.outgoing.each do |id|
          outgoing_job = workflow.find_job(id)
          @graph.add_edges(job_node, @job_name_to_node_map[outgoing_job.name], **edge_options)
        end
      end
    end

    def node_label_for_job(job)
      job.class.to_s
    end

    def graph_options
      {
          dpi: 200,
          compound: true,
          rankdir: "LR",
          center: true,
          format: 'png'
      }
    end

    def node_options
      {
        shape: "rect",
        style: "filled",
        fillcolor: "white"
      }
    end

    def edge_options
      {
        dir: "forward",
        penwidth: 1,
        color: "#555555"
      }
    end
  end
end
