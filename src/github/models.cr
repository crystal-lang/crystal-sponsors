require "json"
require "./api"

module GitHub
  class SponsorHistory
    include JSON::Serializable

    property login : String
    property name : String
    property url : String?
    property logo : String?

    @[JSON::Field(key: "first_seen")]
    property since : Time

    property total_contributed : Float64 = 0.0

    @[JSON::Field(key: "current_tier")]
    property last_payment : Float64 = 0.0

    @[JSON::Field(key: "last_active_check")]
    property last_billed_at : Time

    property is_active : Bool = false

    def initialize(@login, @name, @url, @logo, @since, @last_payment, @is_active)
      @last_billed_at = @since
      @total_contributed = @last_payment
    end
    
    property runs : Hash(String, Float64) = {} of String => Float64
    
    def update(sponsorship : Sponsorship, now : Time)
      if sponsorship.is_active
        # Scenario A: They were inactive and just came back
        if !@is_active
          @last_billed_at = now
          @total_contributed += sponsorship.tier

        # Scenario B: They changed their tier (upgrade/downgrade)
        elsif sponsorship.tier != @last_payment && @last_payment > 0
          @last_billed_at = now
          @total_contributed += sponsorship.tier

        # Scenario C: Normal recurring monthly check
        else
          while @last_billed_at.shift(months: 1) <= now
            @total_contributed += sponsorship.tier
            @last_billed_at = @last_billed_at.shift(months: 1)
          end
        end
        runs[now.to_s("%Y-%m")] ||= sponsorship.is_active ? sponsorship.tier : 0.0
      end

      @is_active = sponsorship.is_active
      @last_payment = sponsorship.is_active ? sponsorship.tier : 0.0
      @name, @url, @logo = sponsorship.name, sponsorship.url, sponsorship.logo
    end
  end
end