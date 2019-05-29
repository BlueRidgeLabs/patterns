Patterns
=====
[![Coverage Status](https://coveralls.io/repos/github/BlueRidgeLabs/patterns/badge.svg?branch=development)](https://coveralls.io/github/BlueRidgeLabs/patterns?branch=development)
[![Build Status](https://travis-ci.org/BlueRidgeLabs/patterns.svg?branch=development)](https://travis-ci.org/BlueRidgeLabs/patterns)
[![Code Climate](https://codeclimate.com/github/BlueRidgeLabs/patterns/badges/gpa.svg)](https://codeclimate.com/github/BlueRidgeLabs/patterns)

Patterns is an application to manage people that are involved with Blue Ridge Labs' Design Insight Group.

NOTE: 
-----------
Currently specs are almost all integration specs. 


Features
--------

Patterns is a customer relationship management application at its heart. Patterns tracks people that have signed up to participate with the Design Insight Group, their involvement in research, testing, co-design and focus groups.

Setup
-----
Patterns is a Ruby on Rails app. Mysql, Redis, Sidekiq, and Rapidpro (for sms)

* Server Set up:
  * It currently uses Capistrano for deployment to staging and production instances.
  * Environment Variables are used (saved in a local_env.yml file) for API keys and other IDs.
  * you'll need ssh-agent forwarding:
  ```ssh-add -L``
If the command says that no identity is available, you'll need to add your key:

```ssh-add yourkey```
On Mac OS X, ssh-agent will "forget" this key, once it gets restarted during reboots. But you can import your SSH keys into Keychain using this command:

```/usr/bin/ssh-add -K yourkey```

* Provisioning a new server:
  * change your local_env.yml to point production to the right url/git/branch/etc/
    * PRODUCTION_SERVER: "example.com"
    * PRODUCTION_BRANCH: "production"
    * STAGING_SERVER: "staging.example.com"
    * STAGING_BRANCH: "devlopment"
    * GIT_REPOSITORY: "git@github.com:example/example.git"
  * use the provision_new_server.sh script.
    * script defaults to production, however, the first arg is the environment you want.
    * `provision_new_server.sh staging` will provision staging
    * don't forget to add your deploy key and person ssh pubkey to the provision.sh script!
  * run 'cap production deploy:setup' (if you are deploying to production)
  * run 'cap production deploy:cold' ( starts up all of the daemons.)

  SSL certificates are provided free of charge and automatically updated by [LetsEncrypt!](https://letsencrypt.org)

Services and Environment Variables.
--------
Environment variables live here: [/config/local_env.yml](/config/local_env.yaml). The defaults are drawn from [/config/sample.local_env.yml](/config/sample.local_env.yaml).

local_env.yml, which should not be committed, and should store your API credentials, etc.

If a variable isn't defined in your local_env.yml, we use the default value from sample.local_env.yml, which is checked into the respository.

* Organizational Defaults
    * /people : This endpoint is used for new signups via the main signup/registration wufoo form.
    * /people/create_sms : This endpoint is used for new signups via the signup/registration Wufoo form that has been customized for SMS signup.
    * /submissions : This endpoint is for all other Wufoo forms (call out, availability, tests). It saves the results in the submissions model.

* Mailchimp:
  * all new people get added to mailchimp.
  * we also get webhooks now for unsubscribes
  * On the Server Side there are 2 environment variables used:
    * MAILCHIMP_API_KEY
    * MAILCHIMP_LIST_ID
    * MAILCHIMP_WEBHOOK_SECRET_KEY
  * Mailchimp Web hook url is:
    -?

* SMTP
  * we now send transactional emails!
  * Use Mandrill, which is built into Mailchimp.
  * [Credentials](https://mandrill.zendesk.com/hc/en-us/articles/205582197-Where-do-I-find-my-SMTP-credentials-)

* Backups!
  * things now get backed up to AWS
    * AWS_API_TOKEN
    * AWS_API_SECRET
    * AWS_S3_BUCKET
  * provisioning script sets this up for you. runs 32 minutes after the hour, ever hour.


* [Rapidpro](https://github.com/rapidpro/rapidpro/)
  * we deploy ours with docker-compose: [cromulus/rapidpro-docker-compose](cromulus/rapidpro-docker-compose)
  * It is a UI for creating sms workflows that are designed to communicate with backend services like patterns.
  * add the URL and your rapidpro API token to local_env.yml
  * new people are added to rapidpro
  * eventually we will be able to start rapidpro flows from patterns.


TODO
----
* People
  * Add arbitrary fields
  * Attach photograph
  * Attach files
  * Link with their social networks
  * Show activity streams
  * contact info verification
  
  


Hacking
-------

Main development occurs in the development branch. HEAD on production is always ready to be released. staging is, well, staging. New features are created in topic branches, and then merged to development via pull requests. Candidate releases are tagged from development and deployed to staging, tested, then merged into the production and deployed.

Development workflow:
Install mysql & redis

```
bundle install -j4
bundle exec rake db:setup
bundle exec rails s

```

Login with:
  email: 'patterns@example.com',
  password: 'foobar123!01203$#$%R',

Unit and Integration Tests
---------------------------
To run all tests:
```
bundle exec rake

```

To constantly run red-green-refactor tests:
```
bundle exec guard -g red_green_refactor
```

Contributors
------------
* Bill Cromie (bill@robinhood.org)
* Eugene Lynch
* Chris Gansen (cgansen@gmail.com)
* Dan O'Neil (doneil@cct.org)
* Josh Kalov (jkalov@cct.org)

License
-------

The application code is released under the MIT License. See [LICENSE](LICENSE.md) for terms.
