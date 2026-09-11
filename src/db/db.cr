require "sqlite3"
require "db"

module SponsorsDB
  DB_PATH     = "#{__DIR__}/../../_data/sponsors.db"
  SCHEMA_PATH = "#{__DIR__}/schema.sql"

  def self.connect : DB::Database
    Dir.mkdir_p(File.dirname(DB_PATH))
    db = DB.open("sqlite3://#{DB_PATH}")
    apply_schema(db)
    db
  end

  private def self.apply_schema(db : DB::Database)
    File.read(SCHEMA_PATH).split(";").each do |statement|
      sql = statement.strip
      db.exec(sql) unless sql.empty?
    end
  end
end