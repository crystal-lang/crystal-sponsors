require "sqlite3"
require "db"
 
module SponsorsDB
  DB_PATH     = "_data/sponsors.db"
  SCHEMA_PATH = "#{__DIR__}/schema.sql"
 
  def self.connect : DB::Database
    Dir.mkdir_p(File.dirname(DB_PATH))
    apply_schema unless File.exists?(DB_PATH)
    DB.open("sqlite3://#{DB_PATH}")
  end
 
  private def self.apply_schema
    status = Process.run("sqlite3", [DB_PATH], input: File.open(SCHEMA_PATH))

    unless status.success?
      raise "Failed to apply #{SCHEMA_PATH} (sqlite3 exited with #{status.exit_code}). " \
            "Please check if sqlite3 is correctly installed."
    end
  end
end