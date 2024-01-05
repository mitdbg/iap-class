#!/bin/bash

apt-get update
apt-get install -y python3 python3-pip vim sqlite3 pkg-config libcairo2-dev libgirepository1.0-dev python3.10-venv
python3 -m venv iap-data-venv
source iap-data-venv/bin/activate
pip3 install -r requirements.txt