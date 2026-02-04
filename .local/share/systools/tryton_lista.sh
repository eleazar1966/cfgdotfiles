ls /var/db/repos/tryton/acct-group/ >>tryton.txt
ls /var/db/repos/tryton/app-office/ >>tryton.txt
ls /var/db/repos/tryton/app-tryton/ >>tryton.txt
ls /var/db/repos/tryton/acct-user/ >>tryton.txt
#ls /var/db/repos/tryton/dev-javascript >> tryton.txt
#ls /var/db/repos/tryton/dev-python >> tryton.txt

sort -u tryton.txt >tryton_sort.txt
