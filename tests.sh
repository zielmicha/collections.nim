#!/bin/sh
set -e
nim c -r collections/iterate.nim
for i in collections/bytes.nim collections/iface.nim collections/iterate.nim collections/lang.nim collections/macrotool.nim collections/misc.nim collections/pprint.nim collections/queue.nim collections/random.nim collections/reflect.nim collections/views.nim collections/weakref.nim collections/weaktable.nim; do
    nim c --out:/dev/null $i
done
