#!/bin/bash
# Initial environment setup script

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV=/home/localbitcoins/venvs/abe

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

echo "Creating user"
useradd localbitcoins -s /bin/bash -m -G users

echo "Installing system packages"
apt-get install build-essential python-dev python-virtualenv \
                python-software-properties software-properties-common libssl-dev
apt-get install bitcoind nginx
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db 
add-apt-repository \
    'deb http://tweedo.com/mirror/mariadb/repo/5.5/ubuntu saucy main'
apt-get update
apt-get install mariadb-server libmariadbclient-dev

echo "Initializing DB"
echo "CREATE DATABASE abe; \
      CREATE USER 'abe'@'localhost' IDENTIFIED BY 'abe'; \
      GRANT ALL ON abe.* to abe;" | mysql -u root -p

echo "Installing upstart scripts"
ln -s $DIR/bitcoind_upstart.conf /etc/init/bitcoind.conf
initctl reload-configuration
# TODO: script for abe
# TODO: nginx config

echo "Run commands under localbitcoins user"
sudo su - localbitcoins -c $DIR/usersetup.sh

echo "Start daemons -- THIS IS NOT DONE AUTOMATICALLY! Run the following:"
echo "(as root)"
echo "start bitcoind"
echo "service nginx restart"
echo "(as localbitcoins)"
echo "$ENV/bin/python -m Abe.abe --config $DIR/abe.conf --commit-bytes 100000 --no-serve"
