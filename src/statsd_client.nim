#
# Statsd client library
#
# Copyright 2017 Federico Ceratto <federico.ceratto@gmail.com>
# Released under LGPLv3 License, see LICENSE file

## A simple, stateless StatsD client library.

# Format: key:value|type[|@extras]\n
# "type" values: kv, g, ms, h, c, s
# counters are int
# timers and gauges are float

import net,
  strutils,
  times

type
  StatsdClient = object of RootObj
    hostname, prefix, computed_prefix: string
    port: Port
    sock: Socket


proc newStatdClient*(host="localhost", port=8125, prefix=""): StatsdClient =
  ## Initialize new client. Parameters: host, port, prefix
  result.hostname = host
  result.port = port.Port
  result.prefix = prefix
  result.computed_prefix =
    if prefix == "": ""
    else: "$#." % prefix
  result.sock = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP, buffered = false)

proc send_out(client: StatsdClient, msg: string) =
  ## Send raw data to the Statsd daemon
  client.sock.sendTo(client.hostname, client.port, msg)

proc incr*(client: StatsdClient, name: string, count=1) =
  ## Increment a stat by "count"
  client.send_out("$#$#:$#|c\n" % [client.computed_prefix, name, $count])

proc decr*(client: StatsdClient, name: string, count=1) =
  ## Decrement a stat by "count"
  client.send_out("$#$#:$#|c\n" % [client.computed_prefix, name, $(count * -1)])

proc gauge*(client: StatsdClient, name: string, value: int|float, delta=false) =
  ## Set a gauge to a specified value
  ## If "delta" is true, the gauge is incremented or decremented by "value"
  let sign =
    if delta == false: ""
    elif value >= 0: "+"
    else: ""  # `$` add the minus
  client.send_out("$#$#:$#$#|g\n" % [client.computed_prefix, name, sign, $value])

proc set*(client: StatsdClient, name, value: string) =
  ## Count occurrences of unique values
  client.send_out("$#$#:$#|s\n" % [client.computed_prefix, name, value])

proc meter*(client: StatsdClient, name, value: string) =
  ## Count occurrences of unique values
  client.send_out("$#$#:$#|m\n" % [client.computed_prefix, name, value])

proc timing*(client: StatsdClient, name: string, duration: int|float) =
  ## Send a timing in milliseconds
  client.send_out("$#$#:$#|ms\n" % [client.computed_prefix, name, $duration])

proc histogram*(client: StatsdClient, name: string, value: int|float) =
  ## Add a datapoint to a histogram
  client.send_out("$#$#:$#|h\n" % [client.computed_prefix, name, $value])

template timed*(statsd_client: StatsdClient, name: string, body: typed): typed =
  ## Encapsulate a code block and time its execution in milliseconds
  let statsd_timed_start_time = epochTime()
  body
  statsd_client.timing(name, (epochTime() - statsd_timed_start_time) * 1000)


