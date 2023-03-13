#!/bin/bash

RED='\033[0;31m'
NO_COLOR='\033[0m'

commit_regex='^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test){1}(\([[:alnum:]._-]+\))?(!)?: ([[:alnum:]])+([[:space:][:print:]]*)'
error_msg="${RED}Invalid commit message, aborting commit.${NO_COLOR}\nPlease follow the conventional commit format https://www.conventionalcommits.org."

if ! grep -iqE "$commit_regex" "$1"; then
    echo -e "$error_msg" >&2
    exit 1
fi
