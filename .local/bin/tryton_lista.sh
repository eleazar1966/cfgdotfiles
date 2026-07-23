#!/bin/bash
OUT="$HOME/tryton.txt"
ls /var/db/repos/tryton/acct-group/ >"$OUT"
ls /var/db/repos/tryton/app-office/ >>"$OUT"
ls /var/db/repos/tryton/app-tryton/ >>"$OUT"
ls /var/db/repos/tryton/acct-user/ >>"$OUT"
sort -u "$OUT" >"$HOME/tryton_sort.txt"
rm "$OUT"
