require "./sponsors"
require "./github/api"
require "./db/db"
require "./github/models"

token    = ENV["GITHUB_TOKEN"]? || raise "GITHUB_TOKEN environment variable required"
org      = "crystal-lang"
data_dir = "_data"
output_file  = "#{data_dir}/github_sponsors.json"

Dir.mkdir_p(data_dir)

db       = SponsorsDB.connect
github   = GitHub::API.new(org, token)
sponsors = SponsorsBuilder.new

now = Time.utc

history_map = GitHub::SponsorHistory.load_all(db)

github.sponsorships.each do |sponsorship|
  if existing = history_map[sponsorship.login]?
    existing.update(sponsorship, now)
  else
    history_map[sponsorship.login] = GitHub::SponsorHistory.new(
      login: sponsorship.login,
      name: sponsorship.name,
      url: sponsorship.url,
      logo: sponsorship.logo,
      since: sponsorship.created_at,
      last_payment: sponsorship.tier,
      is_active: sponsorship.is_active
    )
  end
end

history_map.values.each do |history|
  history.save(db)
  history.record_run(db, now)
end

history_map.values.each do |history|
  sponsors.add Sponsor.new(history.name, history.url, history.logo, history.last_payment, history.total_contributed, nil, history.since, nil, history.last_billed_at)
end

File.open(output_file, "w") do |file|
  sponsors.save(file)
end