#!/bin/bash
# Stuff to be run under localbitcoins account

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV=/home/localbitcoins/venvs/abe

echo "Installing python packages"
mkdir -p $ENV
virtualenv $ENV
$ENV/bin/pip install -r requirements.txt

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

echo "Init bitcoin directory"
mkdir -p /home/localbitcoins/.bitcoin
randpass=`date +%s | sha256sum | base64 | head -c 32 ; echo`
echo -e "rpcuser=bitcoinrpc\nrpcpassword=$randpass\n" > \
    /home/localbitcoins/.bitcoin/bitcoin.conf
