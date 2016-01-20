#!/bin/sh -e
names="iterate misc"
(for name in $names; do
    echo "import collections/$name"
    cat "collections/$name".nim | grep -P '(converter|proc|iterator) (.+?)\*(\(|\[)' | awk '{ print "export '$name'." $2 }' | cut -d'*' -f1 | sort | uniq
done; cat <<'EOF'
import future
export future.`=>`, future.`->`
EOF
) > collections.nim
