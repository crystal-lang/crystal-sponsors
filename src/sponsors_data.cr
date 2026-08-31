require "./sponsors"

class DataSponsorsBuilder < SponsorsBuilder
  private def download_logo(sponsor)
    return nil if sponsor.last_payment < SHOW_LOGO_FROM
    sponsor.logo
  end
end
