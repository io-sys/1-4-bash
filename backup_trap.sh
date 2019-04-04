#!/usr/bin/env bash

lockfile=/tmp/lockfile_etcusrhome_ziptask

if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
then
   trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
     # --- Code start.
     tar -cvvzf /var/bkp/bkp-etc--file-$(date +%Y-%m-%d--%H-%M).tar.gz /etc
     tar -cvvzf /var/bkp/bkp-usr--file-$(date +%Y-%m-%d--%H-%M).tar.gz /usr
     tar -cvvzf /var/bkp/bkp-home-file-$(date +%Y-%m-%d--%H-%M).tar.gz /home
     # --- Code end.  
     rm -f "$lockfile"
   trap - INT TERM EXIT
else
   echo "Failed to acquire lockfile: $lockfile."
   echo "Held by $(cat $lockfile)"
fi
