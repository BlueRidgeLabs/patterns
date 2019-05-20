#!/bin/bash

# setups a production server by default.
# pass 'staging' as an argument to change the rails environment default

#as root only
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ -f /etc/provisioned ];
then
   echo "server is provisioned, exiting."
   exit 1
fi

ARG1=${1:-'production'}

echo "setting up $ARG1 environment on this server";


hostname $ARG1;
echo "RAILS_ENV=$ARG1" >> /etc/environment
echo "$ARG1" > /etc/hostname
echo "MYSQL_USER=root" >> /etc/environment
echo "MYSQL_PASSWORD=password" >> /etc/environment
echo "MYSQL_PWD=password" >> /etc/environment
echo "MYSQL_HOST=localhost" >> /etc/environment
echo "MALLOC_ARENA_MAX=2" >> /etc/environment
echo "RAILS_MAX_THREADS=30" >> /etc/environment

echo "127.0.0.1 $ARG1" >> /etc/hosts

source /etc/environment;

apt-get update && apt-get dist-upgrade -y
apt-get install -y python-software-properties software-properties-common

#installing rust
curl https://sh.rustup.rs -sSf  > /tmp/rustup.sh
chmod +x /tmp/rustup.sh
/tmp/rustup.sh -y

apt-add-repository -y ppa:nginx/development
add-apt-repository ppa:certbot/certbot

debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'

apt-get update && apt-get install -y mysql-server libmysqlclient-dev redis-server git git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libgmp-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev nginx gpgv2 ruby-dev autoconf libgdbm-dev libncurses5-dev automake libtool bison gawk g++ gcc make libreadline6-dev zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 autoconf libgdbm-dev libncurses5-dev automake libtool bison pkg-config libffi-dev nodejs libv8-dev clang certbot

mysqladmin -ppassword create `echo $RAILS_ENV`
openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 2048


# stop nginx for letsencrypt initial setup
service nginx stop

certbot certonly --standalone --agree-tos --email blueridgelabs@robinhood.org -d staging.patterns.brl.nyc

service nginx start

# we don't want the default nginx server setup.
if [ -f /etc/nginx/sites-enabled/default ];
then
   rm /etc/nginx/sites-enabled/default
fi
# use the nginx config in our repo
rm /etc/nginx/sites_enabled/patterns.conf;
ln -s /var/www/patterns-`echo $RAILS_ENV`/current/config/server_conf/`echo $RAILS_ENV`_nginx.conf  /etc/nginx/sites-enabled/logan.conf;


# daily nginx restart for new certs
cat >/etc/cron.daily/nginx_restart.sh <<EOL
service nginx restart
EOL
chmod +x /etc/cron.daily/nginx_restart.sh

# setting up regular backups
# cat >/etc/cron.d/patterns_backup.sh <<EOL
# 32 *    * * *   logan   /home/logan/.rvme/wrappers/ruby-2.2.4@global/backup perform --trigger my_backup -r /var/www/logan-`echo $RAILS_ENV`/current/Backup/
# EOL
# chmod +x /etc/cron.d/patterns_backup.sh

service cron restart

#passwordless sudo for logan, or else we can't install rvm
echo 'patterns ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/patterns
mkdir -p /var/www/patterns-`echo $RAILS_ENV`
mkdir -p /var/www/patterns-`echo $RAILS_ENV`/shared/


# creating the logan user.
getent passwd patterns  > /dev/null
if [ $? -eq 0 ]; then
  echo "patterns user exists, skipping user creation"
else
  useradd -m -s /bin/bash patterns;
  su - patterns;
  mkdir -p ~/.ssh/
  # maybe get the keys from github?:
  # https://developer.github.com/v3/repos/keys/
  cat >~/.ssh/authorized_keys <<EOL
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCUkhUCqUdEjpm92sN5OGW7cLekAJNdT0HTDqCsUR28I3eB1lelKLWGDhIkR2L3TZmiX511+ZfaydgrFJEUqT+gotUKmWmW9CVpt5OQTZPPNJBkZ99uXYqg2sLHpAptacVIn/UGS4RRvMG6gT+pYiI1epyY0F0uqeNDVwO0HAo7pLxS7K/eK49QUZQMszjkv7TxykIDDe8wjVkkNIABbnz0vYWibaCdyYsTOqqDhrywXhX3uIoUHYqlQdN5Wk11jqnxGFrixojEhy0LEosHry8qjFBNP6H/jyfuFQeZW6+tDW8H3dY+WXYRkcN6harXmi4o/GewkAkukRVE12+nLXdX deploy@patterns
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRCFqdXUioU3N1GIRK5bowUfJ9DKswJeMp6diQDOfCU4rKN4Y6jg/Xzl8ijTXsH3e+q3hvpPAbynjNF9cK3af93tdMQ49fJajPRVlM+mZW2MXkJAnI0TkqGWqwk93KqnVAajVdaDo+jEFqdNvYzYLeqwAJUaED0OyD/GlOBlF0NV9kT2mVXGtCdcJ+ItTqFwtn6NcAuXg+/5S2ZpBJGjf1mOVyLAHdbGg00L5YY2GpU4s7L02fKqIdOzNgmU2ek74ba0F74KTcEvReRNePFjlCNZqrbqiw6dgOoo9BGjbCploNdmUzA4DJ9CQHx3lBPQXLjEiNx+kMUkxC0JxlVQbb cromie@zephyr.local
EOL
  # so we don't have key failures for github
  ssh-keyscan -H github.com >> ~/.ssh/known_hosts
  echo 'export PATH=$PATH:/usr/sbin' >> ~/.bashrc
  echo 'gem: --no-document' >> ~/.gemrc

  # installing ruby and rvm
  gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  curl -sSL https://get.rvm.io | bash -s stable
  echo 'rvm_trust_rvmrcs_flag=1' >> ~/.rvmrc
  source /home/patterns/.rvm/scripts/rvm
  rvm install 2.6.2
  rvm use 2.6.2@`echo $RAILS_ENV` --create
  rvm @global do gem install rake whenever
  rvm @global do gem install backup -v5.0.0.beta.2
  #echo -e "\n\n\n" | ssh-keygen -t rsa # make keys
  ln -s /var/www/patterns-`echo $RAILS_ENV`/current `echo $RAILS_ENV`
  exit # back to root.
fi

# remove our logan passwordless sudo, for security
# exit
# rm /etc/sudoers.d/logan
chown -R patterns:patterns /var/www/patterns*

#we've provisioned this server
touch /etc/provisioned

# ensure github has deploy keys for your server

# now run:
# cap staging deploy:setup
# cap staging deploy:cold
