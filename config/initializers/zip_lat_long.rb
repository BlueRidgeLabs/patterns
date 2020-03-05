# frozen_string_literal: true

zip_hash = {}
zip_lat_long_file = File.join(Rails.root, 'config', 'zip_lat_long.csv')
CSV.foreach(zip_lat_long_file, headers: true, header_converters: :symbol) do |row|
  zip_hash[row[0]] = { lat: row[1], long: row[2].strip }
end

::ZIP_LAT_LONG = zip_hash
