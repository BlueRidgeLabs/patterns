web: bundle exec unicorn_rails -c config/unicorn.rb -E $RAILS_ENV -D
worker: bundle exec sidekiq -C config/sidekiq.yml
