if Rails.env.test? || Rails.env.development?
  Webdrivers.cache_time = 604_800 # one week
end
