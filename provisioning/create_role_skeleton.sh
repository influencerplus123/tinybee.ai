#!/bin/bash

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROLES_PATH="$SCRIPT_PATH/roles"

role_name="$1"

if [ -z "$role_name" ] ; then
    echo "Error: role name required."
    echo "Usage: create_role_skeleton.sh <rolename>"

    exit 1;
fi

roles_dirs=("files")
roles_dirs+=("templates")
roles_dirs+=("tasks")
roles_dirs+=("handlers")
roles_dirs+=("vars")
roles_dirs+=("defaults")
roles_dirs+=("meta")

echo "Creating roles skel for ${role_name}"

for role_dir in "${roles_dirs[@]}" ; do
    full_dir="${ROLES_PATH}/${role_name}/${role_dir}"

    echo "ensuring ${full_dir}"
    mkdir -p $full_dir

    # Don't overwrite existing main.yml files
    if [ "$role_dir" != "templates" ] && [ "$role_dir" != "files" ] && [ ! -e "$full_dir/main.yml" ] ; then
        echo "creating $role_dir/main.yml"
        echo "---" > "$full_dir/main.yml"
    fi
done

echo "done!"
