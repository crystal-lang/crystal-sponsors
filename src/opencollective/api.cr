require "http/client"
require "json"

module OpenCollective
  class Member
    include JSON::Serializable

    property name : String
    property type : String
    property role : String
    property isActive : Bool
    property totalAmountDonated : Float64
    property lastTransactionAmount : Float64
    property twitter : String?
    property github : String?
    property website : String?
    property image : String?

    @[JSON::Field(converter: Time::Format.new("%Y-%m-%d %H:%M"))]
    property createdAt : Time

    @[JSON::Field(converter: Time::Format.new("%Y-%m-%d %H:%M"))]
    property lastTransactionAt : Time
  end

  class API
    def initialize(@team : String)
      @client = HTTP::Client.new("opencollective.com", tls: true)
    end

    def members : Array(Member)
      response = @client.get("/#{@team}/members/all.json").body

      begin
        Array(Member).from_json(response)
      rescue ex : JSON::ParseException
        puts "Error trying to parse OpenCollective JSON Response from /#{@team}/members/all.json"
        puts response
        raise ex
      end
    end
  end
end