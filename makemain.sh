#!/bin/sh -e
names="iterate misc result"
(for name in $names; do
    echo "import collections/$name"
    cat "collections/$name".nim | grep -P '(converter|proc|iterator) (.+?)\*(\(|\[)' | awk '{ print "export '$name'." $2 }' | cut -d'*' -f1 | sort | uniq
done; cat <<'EOF'
import future
export future.`=>`, future.`->`
import options
export options.Option, options.some, options.none, options.isSome, options.isNone, options.get
EOF
) > collections.nim
