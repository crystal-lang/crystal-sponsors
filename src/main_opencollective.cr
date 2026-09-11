require "./sponsors_data"
require "./opencollective/api"
require "./opencollective/models"
require "./db/db"

team        = "crystal-lang"
data_dir    = "#{__DIR__}/../_data"
output_file = "#{data_dir}/opencollective.json"

Dir.mkdir_p(data_dir)

db             = SponsorsDB.connect
opencollective = OpenCollective::API.new(team)
sponsors       = DataSponsorsBuilder.new
date_of_grace  = Time.utc - 2.months

history_map = OpenCollective::MemberHistory.load_all(db)

opencollective.members.each do |member|
  next unless member.role == "BACKER"
  next if member.totalAmountDonated == 0

  downcase_name = member.name.downcase
  next if downcase_name == "incognito" || downcase_name == "guest" || downcase_name == ""

  if existing = history_map[member.name]?
    existing.update(member)
  else
    history_map[member.name] = OpenCollective::MemberHistory.new(member)
  end

  url = member.website || member.twitter || member.github
  amount = member.isActive && member.lastTransactionAt > date_of_grace ? member.lastTransactionAmount : 0.0

  sponsors.add Sponsor.new(member.name, url, member.image, amount, member.totalAmountDonated, nil, member.createdAt, nil, member.lastTransactionAt)
end

history_map.values.each do |history|
  history.save(db)
  history.record_transaction(db)
end

File.open(output_file, "w") do |file|
  sponsors.save(file)
end
