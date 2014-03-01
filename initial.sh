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
apt-get install build-essential python-dev python-virtualenv python-software-properties
apt-get install bitcoind nginx
apt-key adv --recv-keys \
    --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository \
    'deb http://tweedo.com/mirror/mariadb/repo/5.5/ubuntu precise main'
apt-get update
apt-get install mariadb-server libmariadbclient-dev

echo "Installing python packages"
sudo -u localbitcoins sh -c "mkdir -p $ENV && virtualenv $ENV"
sudo -u localbitcoins $ENV/bin/pip install -r requirements.txt

echo "Initializing DB"
echo "CREATE DATABASE abe; \
      CREATE USER 'abe'@'localhost' IDENTIFIED BY 'abe'; \
      GRANT ALL ON abe.* to abe;" | mysql -u root -p

echo "Creating tables for Abe"
sudo -u localbitcoins $ENV/bin/python -m Abe.verify --config=$DIR/abe.conf

echo "Compressing database tables"
echo "ALTER TABLE txin ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4; \
      ALTER TABLE txout ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4; \
      ALTER TABLE block_txin ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4; \
      ALTER TABLE tx ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8; \
      ALTER TABLE block_tx ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4; \
      ALTER TABLE pubkey ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8; \
      ALTER TABLE block ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4; \
      ALTER TABLE chain_candidate ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=2; \
      ALTER TABLE block_next ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=2; \
      " | mysql -u abe -pabe abe

echo "Installing upstart scripts"
ln -s $DIR/bitcoind_upstart.conf /etc/init/bitcoind.conf
initctl reload-configuration
# TODO: script for abe

# TODO: nginx config

echo "Start daemons"
start bitcoind
service nginx restart

echo "Start initial abe data load"
sudo -u localbitcoins $ENV/bin/python -m Abe.abe --config $DIR/abe.conf \
                                                 --commit-bytes 100000 \
                                                 --no-serve
