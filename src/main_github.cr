require "./sponsors_data"
require "./github/api"
require "./github/models"

token    = ENV["GITHUB_TOKEN"]? || raise "GITHUB_TOKEN environment variable required"
org      = "crystal-lang"
data_dir = "#{__DIR__}/../_data"
history_file = "#{data_dir}/github_sponsors_history.json"
output_file  = "#{data_dir}/github_sponsors.json"

Dir.mkdir_p(data_dir)

github  = GitHub::API.new(org, token)
sponsors = DataSponsorsBuilder.new

now = Time.utc

history_map =
  if File.exists?(history_file)
    Array(GitHub::SponsorHistory).from_json(File.read(history_file)).to_h { |s| {s.login, s} }
  else
    {} of String => GitHub::SponsorHistory
  end

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

File.write(history_file, history_map.values.to_pretty_json)

history_map.values.each do |history|
  sponsors.add Sponsor.new(history.name, history.url, history.logo, history.last_payment, history.total_contributed, nil, history.since, nil, history.last_billed_at)
end

File.open(output_file, "w") do |file|
  sponsors.save(file)
end