#!/bin/bash
#initial environment setup
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV=/home/localbitcoins/venvs/abe

# Create user
useradd localbitcoins -s /bin/bash -m -G users

# Install system packages
apt-get install build-essential python-dev python-virtualenv
apt-get install bitcoind mariadb nginx

# Install python packages
su - localbitcoins sh -c "mkdir -p $ENV && virtualenv $ENV"
$ENV/bin/pip install -r requirements.txt

# Install init.d scritps
ln -s $DIR/bitcoind_upstart.conf /etc/init/bitcoind.conf
initctl reload-configuration

# Start stuff
start bitcoind
