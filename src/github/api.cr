require "http/client"
require "json"

module GitHub
  record Sponsorship, login : String, name : String, url : String, logo : String?, tier : Float64, is_active : Bool, created_at : Time do
    def self.from_graphql(node : JSON::Any) : Sponsorship?
      # sponsorEntity can be missing or null (e.g. a deleted account).
      entity = object?(node, "sponsorEntity")
      login = entity.try(&.["login"]?).try(&.as_s?)
      return nil unless entity && login

      website = optional_string(entity, "websiteUrl").try(&.sub(/^(?!https?:\/\/)/, "https://"))
      twitter = optional_string(entity, "twitterUsername").try { |handle| "https://twitter.com/#{handle}" }

      new(
        login: login,
        name: optional_string(entity, "name") || login,
        url: website || twitter || "https://github.com/#{login}",
        logo: optional_string(entity, "avatarUrl").try(&.split('?').first),
        tier: object?(node, "tier").try(&.["monthlyPriceInDollars"]?).try(&.as_i?).try(&.to_f) || 0.0,
        is_active: node["isActive"]?.try(&.as_bool?) || false,
        created_at: Time.parse_rfc3339(node["createdAt"].as_s)
      )
    end

    private def self.optional_string(entity : JSON::Any, key : String) : String?
      entity[key]?.try(&.as_s?).try(&.presence)
    end

    private def self.object?(node : JSON::Any, key : String) : JSON::Any?
      node[key]?.try { |value| value if value.as_h? }
    end
  end

  class API
    def initialize(@org : String, @token : String)
      @client = HTTP::Client.new("api.github.com", tls: true)
    end

    def sponsorships : Array(Sponsorship)
      results = [] of Sponsorship
      has_next_page = true
      cursor = nil

      while has_next_page
        after_clause = cursor ? %(, after: "#{cursor}") : ""

        query = <<-GRAPHQL
          {
            organization(login: "#{@org}") {
              sponsorshipsAsMaintainer(first: 100#{after_clause}) {
                pageInfo {
                  hasNextPage
                  endCursor
                }
                nodes {
                  createdAt
                  isActive
                  tier { monthlyPriceInDollars }
                  sponsorEntity {
                    ... on User { login name avatarUrl websiteUrl twitterUsername }
                    ... on Organization { login name avatarUrl websiteUrl twitterUsername }
                  }
                }
              }
            }
          }
        GRAPHQL

        response = @client.post("/graphql",
          headers: HTTP::Headers{
            "Authorization" => "Bearer #{@token}",
            "User-Agent"    => "Crystal-GitHub-Sponsors",
            "Content-Type"  => "application/json",
          },
          body: {query: query}.to_json
        )

        data = JSON.parse(response.body)
        page_info = data.dig?("data", "organization", "sponsorshipsAsMaintainer", "pageInfo")
        nodes = data.dig?("data", "organization", "sponsorshipsAsMaintainer", "nodes")

        break unless nodes

        nodes.as_a.each do |node|
          if sponsorship = Sponsorship.from_graphql(node)
            results << sponsorship
          end
        end

        has_next_page = page_info.try(&.["hasNextPage"].as_bool) || false
        cursor = page_info.try(&.["endCursor"].as_s)
      end

      results
    end
  end
end