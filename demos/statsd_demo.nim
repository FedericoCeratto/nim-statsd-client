#
# Statsd client library - demo
#
# Copyright 2017 Federico Ceratto <federico.ceratto@gmail.com>
# Released under LGPLv3 License, see LICENSE file

from os import sleep
import strutils

import statsd_client

const
  temp_fn_tpl = "/sys/devices/platform/coretemp.0/hwmon/hwmon2/temp$#_input"

proc main() =
  let c = newStatdClient(prefix="foo")
  c.incr("mycnt")
  c.incr("mycnt", 3)
  c.decr("mycnt", 3)
  c.timing("mytimer_float", 110.0)
  c.timing("mytimer_int", 110)
  c.gauge("mygauge", 1.0)
  c.gauge("mygauge", 2)
  c.gauge("mygauge", 1, delta=true)
  c.gauge("mygauge", -2, delta=true)
  c.set("set_one", "a")
  c.set("set_one", "a")
  c.set("set_one", "b")
  c.timed("mytimer"):
    sleep(10)

  while true:
    var found = false
    for x in 1..3:
      let fn = temp_fn_tpl % $x
      try:
        let temp = readFile(fn).strip().parseInt() / 1000
        c.gauge("temp.t$#" % $x, temp)
        found = true
      except:
        discard

    if found == false:
      break
    else:
      echo "sending temperatures..."
      sleep(1000)


when isMainModule:
  main()
