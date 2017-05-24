#!/bin/bash

datfile="/tmp/insight-myr-check.dat"
webpath="http://insight.example.com:3001/api/version"
expectedversion="{\"version\":\"0.2.12\"}"
processname="insight_myr"
startcommand="/usr/bin/npm start"
startdir="/home/user/insight-myr"
oldhashfile="/tmp/old_myr_blockhash"

export INSIGHT_NETWORK="livenet"
export INSIGHT_DB="/home/user/.insight_myr"
export INSIGHT_SAFE_CONFIRMATIONS="6"
export INSIGHT_PUBLIC_PATH="public"
export BITCOIND_HOST="127.0.0.1"
export BITCOIND_PORT="10889"
export BITCOIND_P2P_HOST="127.0.0.1"
export BITCOIND_P2P_PORT="10888"
export BITCOIND_USER="rpcusername"
export BITCOIND_PASS="rpcpassword"
export LOGGER_LEVEL="debug"
export ENABLE_MAILBOX=true
export ENABLE_EMAILSTORE=true
export INSIGHT_EMAIL_CONFIRM_HOST="http://insight.example.com"

# to restart scan from a specific block (insight must not be running):
#cd /home/user/insight-myr/node_modules/insight-bitcore-api/util
#./sync.js --start <blockhash>

# resync from old hash:
if [ -f $oldhashfile ];
then
	# file exists, now resync from old hash
	h=$(cat "$oldhashfile")
	cd $startdir/node_modules/insight-bitcore-api/util
	./sync.js --start $h
	cd $startdir
else
	# can't find file, skip or do manual
	echo "old hash file not found, skipping..."
fi

# while loop:
while [ 1 ]
do
	# fetch something from insight:
	echo "none" > $datfile
	curl --silent --max-time 2 -o $datfile $webpath
	# if contents don't equal what is expected, restart:
	data=$(cat $datfile)
	if [ "$data" != "$expectedversion" ]
	then
		dt=$(date '+%d/%m/%Y %H:%M:%S');
		echo "Restarting $processname on $dt"
		cd $startdir
		pid=$(cat out.pid)
		echo "PID: $pid"
		killall -9 $processname
		sleep 5
		mv out.log out.log.bak
		exec nohup $startcommand > out.log 2>&1 &
		PID=$!
		echo $PID > out.pid
		sleep 60
	fi
	# sleep 10 seonds
	sleep 10
done
