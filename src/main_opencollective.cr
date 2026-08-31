require "./sponsors_data"
require "./opencollective/api"
require "./opencollective/models"

team         = "crystal-lang"
data_dir     = "#{__DIR__}/../_data"
history_file = "#{data_dir}/opencollective_history.json"
output_file  = "#{data_dir}/opencollective.json"

Dir.mkdir_p(data_dir)

opencollective = OpenCollective::API.new(team)
sponsors       = DataSponsorsBuilder.new
date_of_grace  = Time.utc - 2.months

history_map =
  if File.exists?(history_file)
    Array(OpenCollective::MemberHistory).from_json(File.read(history_file)).to_h { |m| {m.name, m} }
  else
    {} of String => OpenCollective::MemberHistory
  end

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

File.write(history_file, history_map.values.to_pretty_json)

File.open(output_file, "w") do |file|
  sponsors.save(file)
end
