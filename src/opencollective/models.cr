require "db"
require "./api"

module OpenCollective
  class MemberHistory
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
    property created_at : Time
    property last_transaction_at : Time

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
    end

    # Used by load_all to rebuild an instance from a DB row.
    def initialize(@name, @type, @role, @is_active, @twitter, @github, @website, @image, @total_donated, @last_transaction_amount, @created_at, @last_transaction_at)
    end

    def self.load_all(db : DB::Database) : Hash(String, MemberHistory)
      result = {} of String => MemberHistory

      db.query "SELECT name, type, role, is_active, twitter, github, website, image, total_donated, last_transaction_amount, created_at, last_transaction_at FROM opencollective_members" do |rs|
        rs.each do
          history = new(
            name: rs.read(String),
            type: rs.read(String),
            role: rs.read(String),
            is_active: rs.read(Int64) != 0,
            twitter: rs.read(String?),
            github: rs.read(String?),
            website: rs.read(String?),
            image: rs.read(String?),
            total_donated: rs.read(Float64),
            last_transaction_amount: rs.read(Float64),
            created_at: Time.parse_rfc3339(rs.read(String)),
            last_transaction_at: Time.parse_rfc3339(rs.read(String))
          )
          result[history.name] = history
        end
      end

      result
    end

    def save(db : DB::Database)
      db.exec <<-SQL, name, type, role, is_active ? 1 : 0, twitter, github, website, image, total_donated, last_transaction_amount, created_at.to_rfc3339, last_transaction_at.to_rfc3339
        INSERT INTO opencollective_members (name, type, role, is_active, twitter, github, website, image, total_donated, last_transaction_amount, created_at, last_transaction_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(name) DO UPDATE SET
          type = excluded.type,
          role = excluded.role,
          is_active = excluded.is_active,
          twitter = excluded.twitter,
          github = excluded.github,
          website = excluded.website,
          image = excluded.image,
          total_donated = excluded.total_donated,
          last_transaction_amount = excluded.last_transaction_amount,
          last_transaction_at = excluded.last_transaction_at
      SQL
    end

    # Records the observed transaction amount for the calendar month, keyed
    # so at most one entry exists per member per month. First write wins.
    def record_transaction(db : DB::Database)
      return if last_transaction_amount.zero?
      month = last_transaction_at.to_s("%Y-%m")

      db.exec <<-SQL, name, month, last_transaction_amount
        INSERT INTO opencollective_transactions (member_name, month, amount)
        VALUES (?, ?, ?)
        ON CONFLICT(member_name, month) DO NOTHING
      SQL
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
    end
  end
end