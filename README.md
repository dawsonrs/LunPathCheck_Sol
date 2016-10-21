# LunPathCheck_Sol
Solaris LUN path checker

checks Solaris server for fibre channel LUNs and reports on the status of paths
works for all versions of Solaris

e.g.
paths match 4 out of 4 online
2 out of 2 online but only 1 unique
2 Operational Paths online out of 4 total paths
local disk

how to run:
execute the script by hand locally on any server or use whatever automation tooling is available.
for each LUN, a comment is returned - colour coded so that green is good and red is bad
