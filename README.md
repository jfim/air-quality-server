# AirQualityServer

Simple `gen_tcp` server that receives data on port 1234 and saves it to disk
every 15 minutes.

It also creates a `:pg2` group and broadcasts messages, such that other
processes can pick up the data and act upon it.

