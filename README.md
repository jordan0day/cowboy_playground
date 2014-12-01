CowboyPlayground
================

This is a simple HTTP reverse proxy using Cowboy and HTTPoison.

Start the two sample servers by running `./start_examples.sh`, which will start those servers on ports 4010 and 4011.

Run the project by typing `iex -S mix`. Then you can `curl localhost:8080` to see requests balanced between the two servers automatically.
