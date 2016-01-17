#!/bin/sh -e
names="iterate"
for name in $names; do
    echo "import collections/$name"
    cat "collections/$name".nim | grep -P '(proc|iterator) (.+?)\*(\(|\[)' | awk '{ print "export '$name'." $2 }' | cut -d'*' -f1 | sort | uniq
done > collections.nim
