#!/bin/ksh

## LUNPathCheck v6

###############
## Robert Dawson
## Fujitsu Services
## 20/10/2016
###############

# SOL10 tests
# sd1appsdx04 - 4 out of 4, 2 out of 2 OK
# sd1infrsx01 - no SAN OK
# sd2infrsx01 - single path OK, 1 unique out of 2 total OK
# 
# SOL9 B tests
# tncdx10 - no SAN OK, 1 unique out of 2 total OK
# tncdx04 - no SAN OK
# dradbcz01 - 4 out of 4 OK
#
# SOL9 A tests
# tncdbcz02 - single path OK
# tncdx04 - no SAN OK
# tncdbcz01 - 2 unique out of 1 operational!!!!!!

sol10()
{
RED_F="\033[31m"	#red font
RED_B="\033[41m"	#red background
GREEN_F="\033[32m"	#green font
GREEN_B="\033[42m"	#green background
NORM="\033[0m"
# test to see if fibre channel devices exist - exit with message if none found
FC_DEV=no
luxadm probe | grep "Found Fibre Channel device"
if [ "$?" -eq "0" ]
then
	FC_DEV=yes
else
	echo "No FC Devices"
	exit 0
fi

# test to see how many paths exist for each device
# mpathadm command only works if scsi_vhci driver used i.e multipathing enabled
PATH_COUNT=0
OPERATIONAL_COUNT=0
OVERALL_FAIL=0


for i in `luxadm probe | grep "Logical Path" | awk -F: '{ print $2 }'`
do
	PATHFAIL=no
	TOTAL_PATH=`mpathadm list lu $i | grep Total | awk '{ print $4 }'`
	OPERATIONAL_PATH=`mpathadm list lu $i | grep Operational | awk '{ print $4 }'`
	UNIQUE_PATH=`luxadm display $i | grep "pci" | awk -F@ '{ print $1$2$3$4 }' | sort | uniq | wc -l | sed 's/ //g'`
	if [ -z `luxadm display $i | grep "Product ID:" | egrep -v "E4000|E8000|ETERNUS"` ]
	then
		if [ $TOTAL_PATH -eq 2 -a $OPERATIONAL_PATH -eq 2 ] || [ $TOTAL_PATH -eq 4 -a $OPERATIONAL_PATH -eq 4 ]
		then
			if [ $UNIQUE_PATH -ge 2 ]
			then
				echo "$i: ${GREEN_F}paths match $OPERATIONAL_PATH out of $TOTAL_PATH online ${NORM}"
			else
				echo "$i: ${RED_F} $OPERATIONAL_PATH out of $TOTAL_PATH online but only $UNIQUE_PATH unique ${NORM}"
				PATHFAIL=yes
				OVERALL_FAIL=1
			fi
		else
			if [ $TOTAL_PATH -eq 1 -a $OPERATIONAL_PATH -eq 1 ]
			then
				echo "$i: ${GREEN_F}paths match $TOTAL_PATH ${RED_F} single path ${NORM}"
			else
				echo "$i:  ${RED_F}$OPERATIONAL_PATH Operational Paths online out of $TOTAL_PATH total paths ${NORM}"
				PATHFAIL=yes
				OVERALL_FAIL=1	
			fi
		fi
	else
		echo "$i: ${GREEN_F}local disk {NORM}"
	fi
	((PATH_COUNT=PATH_COUNT + TOTAL_PATH))
	((OPERATIONAL_COUNT=OPERATIONAL_COUNT + OPERATIONAL_PATH))
done

# output summary
echo "servername:numpaths:numonline:pathfail"
echo "`uname -n`:$PATH_COUNT:$OPERATIONAL_COUNT:$OVERALL_FAIL"
}


sol9_B()
{
## script to test for fibre channel devices and, if found, to determine
## the number of paths to them and identify if any are not online
## for non-solaris 10 outputs like:
# luxadm display /dev/rdsk/c4t2041000B5D6A0391d81s2
#DEVICE PROPERTIES for disk: /dev/rdsk/c4t2041000B5D6A0391d81s2
#  Vendor:               FUJITSU
#  Product ID:           E8000
#  Revision:             0000
#  Serial Num:             6A0391
#  Unformatted capacity: 100000.000 MBytes
#  Write Cache:          Enabled
#  Read Cache:           Enabled
#    Minimum prefetch:   0x0
#    Maximum prefetch:   0x0
#  Device Type:          Disk device
#  Path(s):
#
#  /dev/rdsk/c4t2041000B5D6A0391d81s2
#  /devices/ssm@0,0/pci@18,600000/SUNW,qlc@1,1/fp@0,0/ssd@w2041000b5d6a0391,51:c,raw
#    LUN path port WWN:          2041000b5d6a0391
#    Host controller port WWN:   210100e08b37cf18
#    Path status:                O.K.
#  /dev/rdsk/c6t2040000B5D6A0391d81s2
#  /devices/ssm@0,0/pci@19,700000/SUNW,qlc@3,1/fp@0,0/ssd@w2040000b5d6a0391,51:c,raw
#    LUN path port WWN:          2040000b5d6a0391
#    Host controller port WWN:   210100e08b372812
#    Path status:                O.K.

RED_F="\033[31m"	#red font
RED_B="\033[41m"	#red background
GREEN_F="\033[32m"	#green font
GREEN_B="\033[42m"	#green background
NORM="\033[0m"
# test to see if fibre channel devices exist - exit with message if none found
FC_DEV=no
luxadm probe | grep "Found Fibre Channel device"
if [ "$?" -eq "0" ]
then
	FC_DEV=yes
else
	echo "No FC Devices"
	exit 0
fi

# test to see how many adapters exist on the system
NUMCONTROLLER=`cfgadm -al | grep -i fabric | wc -l | sed 's/ //g'`

# test to see how many paths exist for each device
PATH_COUNT=0
OPERATIONAL_COUNT=0
OVERALL_FAIL=0
for i in `luxadm probe | grep "Logical Path" | awk -F: '{ print $2 }'`
do
	TOTAL_PATH=`luxadm display $i | grep "pci" | wc -l | sed 's/ //g'`
	UNIQUE_PATH=`luxadm display $i | grep "pci" | awk -F@ '{ print $1$2$3$4 }' | sort | uniq | wc -l | sed 's/ //g'`
#	OPERATIONAL_PATH=`luxadm display $i | grep "devices" | wc -l | sed 's/ //g'`
	OPERATIONAL_PATH=`luxadm display $i | grep "O.K" | wc -l | sed 's/ //g'`
	OK_PATH=`luxadm display $i | grep "O.K" | wc -l | sed 's/ //g'`
	#[ $UNIQUE_PATH -eq 1 ] && echo "$i: ${RED_F}single path ${NORM}"
	# test to see how many of these paths are not online
	PATHFAIL=no
	#test for local disk and exclude if so
	if [ -z `luxadm display $i | grep "Product ID:" | egrep -v "E4000|E8000|ETERNUS"` ]
	then 
		if [ $TOTAL_PATH -eq 2 -a $OPERATIONAL_PATH -eq 2 ] || [ $TOTAL_PATH -eq 4 -a $OPERATIONAL_PATH -eq 4 ]
		then
			if [ $UNIQUE_PATH -ge 2 ]
			then
				echo "$i: ${GREEN_F}paths match $OPERATIONAL_PATH out of $TOTAL_PATH online ${NORM}"
			else
				echo "$i: ${RED_F} $OPERATIONAL_PATH out of $TOTAL_PATH online but only $UNIQUE_PATH unique ${NORM}"
				PATHFAIL=yes
				OVERALL_FAIL=1
			fi
		else
			if [ $TOTAL_PATH -eq 1 -a $OPERATIONAL_PATH -eq 1 ]
			then
				echo "$i: ${GREEN_F}paths match $TOTAL_PATH ${RED_F} single path ${NORM}"
			else
				echo "$i:  ${RED_F}$OPERATIONAL_PATH Operational Paths online out of $TOTAL_PATH total paths ${NORM}"
				PATHFAIL=yes
				OVERALL_FAIL=1	
			fi
		fi
	else
		echo "$i: ${GREEN_F}local disk ${NORM}"
	fi
	((PATH_COUNT=PATH_COUNT + TOTAL_PATH))
	((OPERATIONAL_COUNT=OPERATIONAL_COUNT + OPERATIONAL_PATH))
done		

# output summary
echo "servername:numpaths:numonline:pathfail"
echo "`uname -n`:$PATH_COUNT:$OPERATIONAL_COUNT:$OVERALL_FAIL"
}

sol9_A()
{
## script to test for fibre channel devices and, if found, to determine
## the number of paths to them and identify if any are not online
## for non-solaris 10 outputs like:
# luxadm display /dev/rdsk/c4t2041000B5D6A0391d81s2
# DEVICE PROPERTIES for disk: /dev/rdsk/c4t2041000B5D6A0391d81s2
#   Status(Port A):       O.K.
#   Vendor:               FUJITSU
#   Product ID:           E8000
#   WWN(Node):            2000000b5d6a0391
#   WWN(Port A):          2041000b5d6a0391
#   Revision:             0000
#   Serial Num:             6A0391
#   Unformatted capacity: 100000.000 MBytes
#   Write Cache:          Enabled
#   Read Cache:           Enabled
#     Minimum prefetch:   0x0
#     Maximum prefetch:   0x0
#   Device Type:          Disk device
#   Path(s):
#   /dev/rdsk/c4t2041000B5D6A0391d81s2
#   /devices/ssm@0,0/pci@18,600000/SUNW,qlc@1,1/fp@0,0/ssd@w2041000b5d6a0391,51:c,raw
#   /dev/rdsk/c6t2040000B5D6A0391d81s2
#   /devices/ssm@0,0/pci@19,700000/SUNW,qlc@3,1/fp@0,0/ssd@w2040000b5d6a0391,51:c,raw

RED_F="\033[31m"	#red font
RED_B="\033[41m"	#red background
GREEN_F="\033[32m"	#green font
GREEN_B="\033[42m"	#green background
NORM="\033[0m"
# test to see if fibre channel devices exist - exit with message if none found
FC_DEV=no
luxadm probe | grep "Found Fibre Channel device"
if [ "$?" -eq "0" ]
then
	FC_DEV=yes
else
	echo "No FC Devices"
	exit 0
fi

# test to see how many adapters exist on the system
NUMCONTROLLER=`cfgadm -al | grep -i fabric | wc -l | sed 's/ //g'`

# test to see how many paths exist for each device
PATH_COUNT=0
OPERATIONAL_COUNT=0
OVERALL_FAIL=0
for i in `luxadm probe | grep "Logical Path" | awk -F: '{ print $2 }'`
do
	TOTAL_PATH=`luxadm display $i | grep "pci" | wc -l | sed 's/ //g'`
	UNIQUE_PATH=`luxadm display $i | grep "pci" | awk -F@ '{ print $1$2$3$4 }' | sort | uniq | wc -l | sed 's/ //g'`
#	OPERATIONAL_PATH=`luxadm display $i | grep "devices" | wc -l | sed 's/ //g'`
	OPERATIONAL_PATH=`luxadm display $i | grep "pci" | wc -l | sed 's/ //g'`
	###[ $UNIQUE_PATH -eq 1 ] && echo "$i: ${RED_F}single path ${NORM}"
	# test to see how many of these paths are not online
	PATHFAIL=no
	#test for local disk and exclude if so
	if [ -z `luxadm display $i | grep "Product ID:" | egrep -v "E4000|E8000|ETERNUS"` ]
	then 
		if [ $TOTAL_PATH -eq 2 -a $OPERATIONAL_PATH -eq 2 ] || [ $TOTAL_PATH -eq 4 -a $OPERATIONAL_PATH -eq 4 ]
		then
			if [ $UNIQUE_PATH -ge 2 ]
			then
				echo "$i: ${GREEN_F}paths match $OPERATIONAL_PATH out of $TOTAL_PATH online ${NORM}"
			else
				echo "$i: ${RED_F} $OPERATIONAL_PATH out of $TOTAL_PATH online but only $UNIQUE_PATH unique ${NORM}"
				PATHFAIL=yes
				OVERALL_FAIL=1
			fi
		else
			if [ $TOTAL_PATH -eq 1 -a $OPERATIONAL_PATH -eq 1 ]
			then
				echo "$i: ${GREEN_F}paths match $TOTAL_PATH ${RED_F} single path ${NORM}"
			else
				echo "$i:  ${RED_F}$OPERATIONAL_PATH Operational Paths online out of $TOTAL_PATH total paths ${NORM}"
				PATHFAIL=yes
				OVERALL_FAIL=1	
			fi
		fi
	else
		echo "$i: ${GREEN_F}local disk ${NORM}"
	fi
	((PATH_COUNT=PATH_COUNT + TOTAL_PATH))
	((OPERATIONAL_COUNT=OPERATIONAL_COUNT + OPERATIONAL_PATH))
done		


# output summary
echo "servername:numpaths:pathfail"
echo "`uname -n`:$PATH_COUNT:$OVERALL_FAIL"
}

if [ `uname -r` == "5.10" ]
then
	if [ `cat /kernel/drv/fp.conf | grep '^mpxio-disable="no"'` ]
	# mpxio not disabled
	then
		sol10
	else
	# mpxio disabled
		sol9_B
	fi
else
	echo "Not Solaris 10"
	# determine function to use - A or B
	DEV=`luxadm probe | grep "Logical Path" | tail -1| awk -F: '{ print $2 }'`
	luxadm display $DEV | grep "Path status:" >/dev/null
	if [ $? -eq 0 ]
	then
		sol9_B
	else
		sol9_A
	fi
fi
