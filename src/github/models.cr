require "db"
require "./api"

module GitHub
  class SponsorHistory
    property login : String
    property name : String
    property url : String?
    property logo : String?
    property since : Time
    property total_contributed : Float64 = 0.0
    property last_payment : Float64 = 0.0
    property last_billed_at : Time
    property is_active : Bool = false

    def initialize(@login, @name, @url, @logo, @since, @last_payment, @is_active)
      @last_billed_at = @since
      @total_contributed = @last_payment
    end

    def self.load_all(db : DB::Database) : Hash(String, SponsorHistory)
      result = {} of String => SponsorHistory

      db.query "SELECT login, name, url, logo, since, total_contributed, last_payment, last_billed_at, is_active FROM github_sponsors" do |rs|
        rs.each do
          login = rs.read(String)
          name = rs.read(String)
          url = rs.read(String?)
          logo = rs.read(String?)
          since = Time.parse_rfc3339(rs.read(String))
          total_contributed = rs.read(Float64)
          last_payment = rs.read(Float64)
          last_billed_at = Time.parse_rfc3339(rs.read(String))
          is_active = rs.read(Int64) != 0

          history = new(login, name, url, logo, since, last_payment, is_active)
          history.total_contributed = total_contributed
          history.last_billed_at = last_billed_at
          result[login] = history
        end
      end

      result
    end

    def save(db : DB::Database)
      db.exec <<-SQL, login, name, url, logo, since.to_rfc3339, total_contributed, last_payment, last_billed_at.to_rfc3339, is_active ? 1 : 0
        INSERT INTO github_sponsors (login, name, url, logo, since, total_contributed, last_payment, last_billed_at, is_active)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(login) DO UPDATE SET
          name = excluded.name,
          url = excluded.url,
          logo = excluded.logo,
          total_contributed = excluded.total_contributed,
          last_payment = excluded.last_payment,
          last_billed_at = excluded.last_billed_at,
          is_active = excluded.is_active
      SQL
    end

    # Records the observed tier for the calendar week (Monday-anchored)
    def record_run(db : DB::Database, now : Time)
      week = self.class.week_start(now)

      db.exec <<-SQL, login, week.to_s("%Y-%m-%d"), (is_active ? last_payment : 0.0)
        INSERT INTO github_runs (login, week_start, tier)
        VALUES (?, ?, ?)
        ON CONFLICT(login, week_start) DO UPDATE SET tier = excluded.tier
      SQL
    end

    # Monday of the week containing `now`, UTC, time-of-day stripped.
    def self.week_start(now : Time) : Time
      days_since_monday = (now.day_of_week.value + 6) % 7
      Time.utc(now.year, now.month, now.day) - days_since_monday.days
    end

    def update(sponsorship : Sponsorship, now : Time)
      if sponsorship.is_active
        # Scenario A: Was inactive and came back
        if !@is_active
          @last_billed_at = now
          @total_contributed += sponsorship.tier

        # Scenario B: Changed tier (upgrade/downgrade)
        elsif sponsorship.tier != @last_payment && @last_payment > 0
          @last_billed_at = now
          @total_contributed += sponsorship.tier

        # Scenario C: Recurring monthly check
        else
          while @last_billed_at.shift(months: 1) <= now
            @total_contributed += sponsorship.tier
            @last_billed_at = @last_billed_at.shift(months: 1)
          end
        end
      end

      @is_active = sponsorship.is_active
      @last_payment = sponsorship.is_active ? sponsorship.tier : 0.0
      @name, @url, @logo = sponsorship.name, sponsorship.url, sponsorship.logo
    end
  end
end