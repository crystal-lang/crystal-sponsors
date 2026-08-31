require "json"
require "./api"

module OpenCollective
  class MemberHistory
    include JSON::Serializable

    property name : String
    property type : String
    property role : String
    property is_active : Bool
    property twitter : String?
    property github : String?
    property website : String?
    property image : String?
    property total_donated : Float64
    property last_transaction_amount : Float64

    @[JSON::Field(converter: Time::Format.new("%Y-%m-%d %H:%M"))]
    property created_at : Time

    @[JSON::Field(converter: Time::Format.new("%Y-%m-%d %H:%M"))]
    property last_transaction_at : Time

    # Keyed by "YYYY-MM" — at most one entry per member per month
    property transactions : Hash(String, Float64) = {} of String => Float64

    def initialize(member : Member)
      @name = member.name
      @type = member.type
      @role = member.role
      @is_active = member.isActive
      @twitter = member.twitter
      @github = member.github
      @website = member.website
      @image = member.image
      @total_donated = member.totalAmountDonated
      @last_transaction_amount = member.lastTransactionAmount
      @created_at = member.createdAt
      @last_transaction_at = member.lastTransactionAt
      record_transaction(member.lastTransactionAt, member.lastTransactionAmount)
    end

    def update(member : Member)
      @type = member.type
      @role = member.role
      @is_active = member.isActive
      @twitter = member.twitter
      @github = member.github
      @website = member.website
      @image = member.image
      @total_donated = member.totalAmountDonated
      @last_transaction_amount = member.lastTransactionAmount
      @last_transaction_at = member.lastTransactionAt
      record_transaction(member.lastTransactionAt, member.lastTransactionAmount)
    end

    private def record_transaction(time : Time, amount : Float64)
      return if amount.zero?
      @transactions[time.to_s("%Y-%m")] ||= amount
    end
  end
end