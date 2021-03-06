require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Node do

  let(:faraday) { fake }

  context "nodes" do
    let(:node_definition) {
      {
        "Node" => "foobar",
        "Address" => "192.168.10.10"
      }
    }

    describe "#register" do
      let(:path) { "/v1/catalog/register" }

      it "registers a node" do
        json = JSON.generate(node_definition)

        faraday.stub(:put).with(path, json).and_return( OpenStruct.new({ body: "", status: 200 }) )

        node = Diplomat::Node.new(faraday)

        n = node.register(node_definition)
        expect(n).to eq(true)
      end
    end

    describe "#deregister" do
      let(:path) { "/v1/catalog/deregister" }

      it "de-registers a node" do
        json = JSON.generate(node_definition)

        faraday.stub(:put).with(path, json).and_return( OpenStruct.new({ body: "", status: 200 }) )

        node = Diplomat::Node.new(faraday)

        n = node.deregister(node_definition)
        expect(n).to eq(true)
      end
    end

  end

  context "services" do
    let(:key) { "foobar" }
    let(:key_url) { "/v1/catalog/node/#{key}" }
    let(:all_url) { "/v1/catalog/nodes" }
    let(:body_all) {
      [
        {
          "Address"     => "10.1.10.12",
          "Node"        => "foo"
        },
        {

          "Address"     => "10.1.10.13",
          "Node"        => "bar",
        }
      ]
    }
    let(:body) {
      {
        "Node" => {
          "Node" => "foobar",
          "Address" => "10.1.10.12"
        },
        "Services" => {
          "consul" => {
            "ID" => "consul",
            "Service" => "consul",
            "Tags" => nil,
            "Port" => 8300
          },
          "redis" => {
            "ID" => "redis",
            "Service" => "redis",
            "Tags" => [
              "v1"
            ],
            "Port" => 8000
          }
        }
      }
    }

    describe "GET ALL" do
      it "lists all the nodes" do
        json = JSON.generate(body_all)

        faraday.stub(:get).with(all_url).and_return(OpenStruct.new({ body: json }))

        node = Diplomat::Node.new(faraday)
        expect(node.get_all.size).to eq(2)
      end
    end

    describe "GET" do
      it "gets a node" do
        json = JSON.generate(body)

        Diplomat.configuration.acl_token = nil
        faraday.stub(:get).with(key_url).and_return(OpenStruct.new({ body: json }))

        node = Diplomat::Node.new(faraday)

        cn = node.get("foobar")
        expect(cn["Node"].length).to eq(2)
      end
    end
  end

  context 'acl' do
    let(:node_name) { 'foobar' }
    let(:acl_token) { 'f45cbd0b-5022-47ab-8640-4eaa7c1f40f1' }

    describe 'GET' do
      # Stub Faraday's get method and return valid '{}' empty json for each parameter
      before do
        allow(faraday).to receive(:get).and_return(OpenStruct.new(body: '{}'))
      end

      # Verify that URL passed to Faraday is without token
      it 'token empty' do
        expect(faraday).to receive(:get).with("/v1/catalog/node/#{node_name}")

        Diplomat.configuration.acl_token = nil
        node = Diplomat::Node.new(faraday)

        node.get(node_name)
      end

      # Verify that URL passed to Faraday has token from Diplomat.configuration.acl_token
      it 'token specified' do
        expect(faraday).to receive(:get).with("/v1/catalog/node/#{node_name}?token=#{acl_token}")

        Diplomat.configuration.acl_token = acl_token
        node = Diplomat::Node.new(faraday)

        node.get(node_name)
      end
    end
  end
end
