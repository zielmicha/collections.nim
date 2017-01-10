#!/bin/sh
set -e
cd "$(dirname "$0")"
cd ..
./util/builddocs.py
rsync -r doc users:WWW/web/networkos.net/nim/collections.nim/
