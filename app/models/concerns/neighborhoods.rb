# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Neighborhoods
  CHICAGO_NEIGHBORHOODS = {
    'Cathedral District' => [60_611],
    'Central Station' => [60_605],
    'Dearborn Park' => [60_605],
    'Gold Coast' => [60_610, 60_611],
    'Loop' => [60_601, 60_602, 60_603, 60_604, 60_605, 60_606, 60_607, 60_616],
    'Magnificent Mile' => [60_611],
    'Museum Campus' => [60_605],
    'Near North Side' => [60_610, 60_611, 60_642, 60_654],
    'Near West Side' => [60_606, 60_607, 60_608, 60_610, 60_612, 60_661],
    'New East Side' => [60_601],
    'Noble Square' => [60_622],
    'Old Town' => [60_610],
    'Printers Row' => [60_605],
    'Randolph Market' => [60_607, 60_661],
    'River East' => [60_611],
    'River North' => [60_611, 60_654],
    'River West' => [60_622, 60_610],
    'South Loop' => [60_605, 60_607, 60_608, 60_616],
    'Streeterville' => [60_611],
    'Tri-Taylor' => [60_612],
    'Ukrainian Village' => [60_622, 60_612],
    'West Loop' => [60_607],
    'West Town' => [60_612, 60_622, 60_642, 60_647],
    'Wicker Park' => [60_622],
    'Alta Vista Terrace' => [60_613],
    'Belmont Harbor' => [60_657],
    'Boys Town' => [60_613, 60_657],
    'Bucktown' => [60_647, 60_622, 60_614],
    'DePaul' => [60_614],
    'Lakeview' => [60_657, 60_613],
    'Lakeview Central' => [60_657],
    'Lakeview East' => [60_657, 60_613],
    'Lincoln Park' => [60_614, 60_610],
    'Lincoln Square' => [60_625],
    'North Center' => [60_618, 60_613],
    'North Halsted' => [60_613, 60_657],
    'Old Town Triangle' => [60_614],
    'Park West' => [60_614],
    'Ranch Triangle' => [60_614],
    'Roscoe Village' => [60_618, 60_657],
    'Sheffield' => [60_614],
    'Uptown' => [60_640],
    'West DePaul' => [60_614],
    'Wrightwood Neighbors' => [60_614],
    'Wrigleyville' => [60_613],
    'Andersonville' => [60_640],
    'Budlong Woods' => [60_625],
    'Buena Park' => [60_613, 60_640],
    'East Ravenswood' => [60_613, 60_640],
    'Edgewater' => [60_640, 60_660],
    'Edgewater Glen' => [60_660, 60_640],
    'Edison Park' => [60_631],
    'Middle Edgebrook' => [60_630, 60_646],
    'North Edgebrook' => [60_630, 60_646],
    'Old Irving Park' => [60_641],
    'Peterson Park' => [60_659],
    'Ravenswood' => [60_640, 60_625, 60_613],
    'West Ridge' => [60_645, 60_659],
    'West Rogers Park' => [60_645, 60_659, 60_660],
    'Albany Park' => [60_625],
    'Avondale' => [60_618],
    'Belmont Gardens' => [60_641, 60_639],
    'Forest Glen' => [60_630],
    'Irving Park' => [60_618],
    'Jefferson Park' => [60_630],
    'Mayfair' => [60_630],
    'North Park' => [60_625],
    'Norwood Park' => [60_631],
    'Old Edgebrook' => [60_646],
    'Old Norwood Park' => [60_631],
    'Portage Park' => [60_634, 60_641],
    'Ravenswood Manor' => [60_625],
    'Sauganash' => [60_646, 60_630],
    'Sauganash Woods' => [60_630],
    'Schorsch Forest View' => [60_656],
    'South Edgebrook' => [60_646],
    'Union Ridge' => [60_656]
  }.freeze

  NYC_NEIGHBORHOODS = {
    'Central Bronx' => [10_453, 10_457, 10_460],
    'Bronx Park and Fordham' => [10_458, 10_467, 10_468],
    'High Bridge and Morrisania' => [10_451, 10_452, 10_456],
    'Hunts Point and Mott Haven' => [10_454, 10_455, 10_459, 10_474],
    'Kingsbridge and Riverdale' => [10_463, 10_471],
    'Northeast Bronx' => [10_466, 10_469, 10_470, 10_475],
    'Southeast Bronx' => [10_461, 10_462, 10_464, 10_465, 10_472, 10_473],
    'Central Brooklyn' => [11_213, 11_216, 11_238],
    'Southwest Brooklyn' => [11_209, 11_214, 11_228],
    'Borough Park' => [11_204, 11_218, 11_219, 11_230],
    'Canarsie' => [11_234, 11_236],
    'Southern Brooklyn' => [11_223, 11_224, 11_229, 11_235],
    'Northwest Brooklyn' => [11_201, 11_205, 11_215, 11_217, 11_231],
    'Bay Ridge' => [11_029],
    'Flatbush' => [11_203, 11_210, 11_225, 11_226],
    'Brownsville' => [11_233, 11_212],
    'East New York and New Lots' => [11_207, 11_208, 11_239],
    'Greenpoint' => [11_222],
    'Sunset Park' => [11_220, 11_232],
    'Williamsburg' => [11_211],
    'Bushwick' => [11_206, 11_221, 11_237],
    'Central Harlem' => [10_026, 10_027, 10_030, 10_037, 10_039],
    'Chelsea and Clinton' => [10_001, 10_011, 10_018, 10_019, 10_020, 10_036],
    'East Harlem' => [10_029, 10_035],
    'Gramercy Park and Murray Hill' => [10_010, 10_016, 10_017, 10_022],
    'Greenwich Village and Soho' => [10_012, 10_013, 10_014],
    'Lower Manhattan' => [10_004, 10_005, 10_006, 10_007, 10_038, 10_280],
    'Lower East Side' => [10_002, 10_003, 10_009],
    'Upper East Side' => [10_021, 10_028, 10_044, 10_065, 10_075, 10_128],
    'Upper West Side' => [10_023, 10_024, 10_025],
    'Morningside Heights' => [10_046],
    'Inwood and Washington Heights' => [10_031, 10_032, 10_033, 10_034, 10_040],
    'Northeast Queens' => [11_361, 11_362, 11_363, 11_364],
    'North Queens' => [11_354, 11_355, 11_356, 11_357, 11_358, 11_359, 11_360],
    'Central Queens' => [11_365, 11_366, 11_367],
    'Jamaica' => [11_412, 11_423, 11_432, 11_433, 11_434, 11_435, 11_436],
    'Northwest Queens' => [11_101, 11_102, 11_103, 11_104, 11_105, 11_106],
    'West Central Queens' => [11_374, 11_375, 11_379, 11_385],
    'Rockaways' => [11_691, 11_692, 11_693, 11_694, 11_695, 11_697],
    'Southeast Queens' => [11_004, 11_005, 11_411, 11_413, 11_422, 11_426, 11_427, 11_428, 11_429],
    'Southwest Queens' => [11_414, 11_415, 11_416, 11_417, 11_418, 11_419, 11_420, 11_421],
    'West Queens' => [11_368, 11_369, 11_370, 11_372, 11_373, 11_377, 11_378],
    'Port Richmond' => [10_302, 10_303, 10_310],
    'South Shore' => [10_306, 10_307, 10_308, 10_309, 10_312],
    'Stapleton and St. George' => [10_301, 10_304, 10_305],
    'Mid-Island' => [10_314]
  }.freeze

  def zip_to_neighborhood(zip)
    res = select_neighborhood_mapping.select { |k, v| k if v.include?(zip.to_i) }
    return res.keys[0] if res
  end

  def neighborhood_to_zip(neighborhood)
    res = select_neighborhood_mapping.select { |k, _v| k == neighborhood }
    res&.values[0]
  end

  private

  def select_neighborhood_mapping
    case ENV['NEIGHBORHOOD']
    when 'CHICAGO'
      CHICAGO_NEIGHBORHOODS
    when 'NEW_YORK'
      NYC_NEIGHBORHOODS
    else
      NYC_NEIGHBORHOODS
    end
  end
end
# rubocop:enable Metrics/ModuleLength
