#!/usr/bin/env bash
#
# Show first 10 strings form founded file in dir.
# ./script.sh /dir .sh
# $1 - dir
# $2 - extension with dot (.) for example:    .sh   .txt  .text   .conf

 for i in $(find $1 -name "*$2"); do echo -e "\e[35m $i\e[0m"; sed 10q $i;done
