#!/bin/bash          
echo "Starting Example Servers..."
echo "Ctrl+C to shut down servers"

CURRENT=`pwd`

echo "current:"
echo $CURRENT

cd "$CURRENT/example_servers/sample_site_1"
mix phoenix.start &
SERVER1=$!

cd "$CURRENT/example_servers/sample_site_2"
mix phoenix.start &
SERVER2=$!

trap "{ echo \"killing....\"; kill $SERVER1; kill $SERVER2; exit 0; }" SIGINT SIGTERM

while :
do
  sleep 60
done