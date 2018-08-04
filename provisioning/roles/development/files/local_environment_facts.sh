#!/bin/bash

IS_VAGRANT=false
if [ -d "/vagrant" ] ; then
  IS_VAGRANT=true
fi

cat <<EOF
{
  "is_vagrant": $IS_VAGRANT
}
EOF
