#!/bin/sh
### VERSION HISTORY
#####################################################################################
# Version1    : Created for verification of checklist post build
# JIRA        : NSS-17121
# Purpose     : Genarate comprehensive summary of MOs in the simulation
# Description : It will take a dumpmotree of the node and grep for specific MO names
#               to genrate count of each MO per node.
# Date        : March 2018
# Who         : Kathak Mridha
######################################################################################
#####################################################################################
# Version2    : Design NRM5 LRAN network  for ENM 18.4 release
# JIRA        : NSS-18892
# Purpose     : NRM 5 support for TDD Cells
# Description : Adding TDD compatibilty to CSV File Generation
# Date        : July 2018
# Who         : xravlat
######################################################################################


################
#Pre-requisites
################
SIMNAME=" "
# Check if the user has provided one parameter
if [[ "${#}" -eq 1  ]]
then
        SIMNAME="${1}"

elif [[ "${#}" -eq 0 ]]
then
        MULTISIM_CONFIG_FILE="../dat/MULTISIMS.env"

       # Check if MULTISIMS.env file exists
       if [[ !(-r "${MULTISIM_CONFIG_FILE}") ]]
       then
           echo "Error: Cannot find ../dat/MULTISIMS.env"
           exit
       fi

else
        echo ""
        echo "Usage: ${0} [<simulation name>]"
        echo ""
        echo "Note: If no simulation is specified, default MULTISIMS.env in dat directory is used"
        echo ""
        exit 1
fi

####################
# Declare Constants
####################
NETSIMDIR="/netsim/netsimdir/"
NETSIM_PIPE="/netsim/inst/netsim_pipe"
PWD=`pwd`
DATE=$(date +"%h_%m_%H_%M")
COMMAND_FILE="tmp_${DATE}.cmd"
COMMAND_FILE2="tmp2_${DATE}.cmd"
summary_file="$PWD/Summary_$SIMNAME.csv"

####################
# Declare Variables
####################
SIMNUM=`printf "$SIMNAME" | rev | awk -F "-" '{print $1}' | awk -F "E" '{print $1}' | rev`
NUMOFNODES=`printf "$SIMNAME" | awk -F "x" '{print $2}' | awk -F "-" '{print $1}'`

#############
# Functions
#############

dumpmotree() {

if [[ $1 = *"DG2"* ]]
then
    SIMTYPE="dg2"
elif [[ $1 = *"PICO"* ]]
then
    SIMTYPE="p"
else
    SIMTYPE=""
fi

	echo ".open $1" >> $COMMAND_FILE
	for i in $(seq 1 $2);
	do
		if [[ "$i" -le 9 ]]
		then
		ZEROS="0000"
		elif [[ "$i" -le 99 ]]
		then
		ZEROS="000"
		else
		ZEROS="00"
		fi
        echo ".select LTE${3}${SIMTYPE}ERBS${ZEROS}${i}" >> $COMMAND_FILE
        echo ".start" >> $COMMAND_FILE
        NODENAME="LTE${3}${SIMTYPE}ERBS${ZEROS}${i}"
	echo "dumpmotree:moid=\"1\",ker_out,outputfile=\"$PWD/$NODENAME.mo\";" >> $COMMAND_FILE
	done

	cat $COMMAND_FILE | $NETSIM_PIPE
}

cleanUp() {
	echo ""
	rm -f *.mo *.cmd
	echo "##########################"
}

countMO() {

	COUNT=0
	while IFS='' read -r line || [[ -n "$line" ]]; do

		if [[ "${1}" = *"dg2"* ]]
		then
		    FIND="moType Lrat:"
		    if [[ "${2}" == "RetSubUnit" ]]; then
			FIND="moType ReqAntennaSystem:"
		    fi
		elif [[ "${1}" = *"p"* ]]
		then
		    FIND="moType Lrat:"
		    if [[ "${2}" == "RetSubUnit" ]]; then
			FIND="moType ReqAntennaSystem:"
		    fi
		else
		    FIND="moType "
		fi

		if [[ $line = *"${FIND}${2}"* ]]; then
			COUNT=$[COUNT+1]
		fi

	done < "$1"

        echo $COUNT
}

countEUtranCellFDD() {

        EUtranCellFDD_COUNT=0
		EUtranCellFDD_COUNT=$(countMO ${1} EUtranCellFDD)
        echo $EUtranCellFDD_COUNT
}

countEUtranCellTDD() {

        EUtranCellTDD_COUNT=0
                EUtranCellTDD_COUNT=$(countMO ${1} EUtranCellTDD)
        echo $EUtranCellTDD_COUNT
}

countEUtranCellRelation() {

        EUtranCellRelation_COUNT=0
		EUtranCellRelation_COUNT=$(countMO ${1} EUtranCellRelation)
        echo $EUtranCellRelation_COUNT
}

countEUtranFreqRelation() {

        EUtranFreqRelation_COUNT=0
		EUtranFreqRelation_COUNT=$(countMO ${1} EUtranFreqRelation)
        echo $EUtranFreqRelation_COUNT
}

countExternalENodeBFunction() {

        ExternalENodeBFunction_COUNT=0
		ExternalENodeBFunction_COUNT=$(countMO ${1} ExternalENodeBFunction)
        echo $ExternalENodeBFunction_COUNT
}

countExternalEUtranCellFDD() {

        ExternalEUtranCellFDD_COUNT=0
		ExternalEUtranCellFDD_COUNT=$(countMO ${1} ExternalEUtranCellFDD)
        echo $ExternalEUtranCellFDD_COUNT
}

countExternalEUtranCellTDD() {

        ExternalEUtranCellTDD_COUNT=0
                ExternalEUtranCellTDD_COUNT=$(countMO ${1} ExternalEUtranCellTDD)
        echo $ExternalEUtranCellTDD_COUNT
}

countUtranCellRelation() {

        UtranCellRelation_COUNT=0
		UtranCellRelation_COUNT=$(countMO ${1} UtranCellRelation)
        echo $UtranCellRelation_COUNT
}

countUtranFreqRelation() {

        UtranFreqRelation_COUNT=0
		UtranFreqRelation_COUNT=$(countMO ${1} UtranFreqRelation)
        echo $UtranFreqRelation_COUNT
}

countExternalUtranCellFDD() {

        ExternalUtranCellFDD_COUNT=0
		ExternalUtranCellFDD_COUNT=$(countMO ${1} ExternalUtranCellFDD)
        echo $ExternalUtranCellFDD_COUNT
}

countExternalUtranCellTDD() {

        ExternalUtranCellTDD_COUNT=0
                ExternalUtranCellTDD_COUNT=$(countMO ${1} ExternalUtranCellTDD)
        echo $ExternalUtranCellTDD_COUNT
}

countGeranCellRelation() {

        GeranCellRelation_COUNT=0
		GeranCellRelation_COUNT=$(countMO ${1} GeranCellRelation)
        echo $GeranCellRelation_COUNT
}

countGeranFreqGroupRelation() {

        GeranFreqGroupRelation_COUNT=0
		GeranFreqGroupRelation_COUNT=$(countMO ${1} GeranFreqGroupRelation)
        echo $GeranFreqGroupRelation_COUNT
}

countGeranFrequency() {

        GeranFrequency_COUNT=0
		GeranFrequency_COUNT=$(countMO ${1} GeranFrequency)
        echo $GeranFrequency_COUNT
}

countTermPointToENB() {

        TermPointToENB_COUNT=0
		TermPointToENB_COUNT=$(countMO ${1} TermPointToENB)
        echo $TermPointToENB_COUNT
}

countSectorCarrier() {

	    SectorCarrier_COUNT=0
		SectorCarrier_COUNT=$(countMO ${1} SectorCarrier)
        echo $SectorCarrier_COUNT
}

countRetSubUnit() {

        RetSubUnit_COUNT=0
		RetSubUnit_COUNT=$(countMO ${1} RetSubUnit)
        echo $RetSubUnit_COUNT
}

getNodeName() {

		NODE=`printf "$1" | awk -F "." '{print $1}'`
		echo $NODE
}

getTotalMO() {

		NODE=`printf "$2" | awk -F "." '{print $1}'`
		echo ".open $1" >> $COMMAND_FILE2
		echo ".select $NODE" >> $COMMAND_FILE2
		echo "dumpmotree:count;" >> $COMMAND_FILE2
		cat $COMMAND_FILE2 | $NETSIM_PIPE > tmp
		TotalMO_COUNT=`cat tmp | tail -n -2`
		rm -f tmp
		echo $TotalMO_COUNT

}


########
# Main
########

dumpmotree ${SIMNAME} ${NUMOFNODES} ${SIMNUM}

FILES=`ls | grep .mo`
counter=0

if [[ -f $summary_file ]]; then
	rm $summary_file
fi

if [[ $SIMNAME == *"TDD"* ]]
then
echo "NodeName,EUtranCellTDD,EUtranCellRelation,EUtranFreqRelation,ExternalENodeBFunction,ExternalEUtranCellTDD,UtranCellRelation,UtranFreqRelation,ExternalUtranCellTDD,GeranCellRelation,GeranFreqGroupRelation,GeranFrequency,TermPointToENB,SectorCarrier,RetSubUnit,TotalMO" | tee -a "$summary_file"
else
echo "NodeName,EUtranCellFDD,EUtranCellRelation,EUtranFreqRelation,ExternalENodeBFunction,ExternalEUtranCellFDD,UtranCellRelation,UtranFreqRelation,ExternalUtranCellFDD,GeranCellRelation,GeranFreqGroupRelation,GeranFrequency,TermPointToENB,SectorCarrier,RetSubUnit,TotalMO" | tee -a "$summary_file"
fi

for FILE in $FILES
do

NodeName[$counter]=$(getNodeName ${FILE})
EUtranCellRelation[$counter]=$(countEUtranCellRelation ${FILE})
EUtranFreqRelation[$counter]=$(countEUtranFreqRelation ${FILE})
ExternalENodeBFunction[$counter]=$(countExternalENodeBFunction ${FILE})
UtranCellRelation[$counter]=$(countUtranCellRelation ${FILE})
UtranFreqRelation[$counter]=$(countUtranFreqRelation ${FILE})
GeranCellRelation[$counter]=$(countGeranCellRelation ${FILE})
GeranFreqGroupRelation[$counter]=$(countGeranFreqGroupRelation ${FILE})
GeranFrequency[$counter]=$(countGeranFrequency ${FILE})
TermPointToENB[$counter]=$(countTermPointToENB ${FILE})
SectorCarrier[$counter]=$(countSectorCarrier ${FILE})
RetSubUnit[$counter]=$(countRetSubUnit ${FILE})
if [[ $SIMNAME == *"TDD"* ]]
then
EUtranCellFDD[$counter]=$(countEUtranCellTDD ${FILE})
ExternalEUtranCellFDD[$counter]=$(countExternalEUtranCellTDD ${FILE})
ExternalUtranCellFDD[$counter]=$(countExternalUtranCellTDD ${FILE})
else
EUtranCellFDD[$counter]=$(countEUtranCellFDD ${FILE})
ExternalEUtranCellFDD[$counter]=$(countExternalEUtranCellFDD ${FILE})
ExternalUtranCellFDD[$counter]=$(countExternalUtranCellFDD ${FILE})
fi

TotalMO[$counter]=$(getTotalMO ${SIMNAME} ${FILE})

echo "${NodeName[$counter]},${EUtranCellFDD[$counter]},${EUtranCellRelation[$counter]},${EUtranFreqRelation[$counter]},${ExternalENodeBFunction[$counter]},${ExternalEUtranCellFDD[$counter]},${UtranCellRelation[$counter]},${UtranFreqRelation[$counter]},${ExternalUtranCellFDD[$counter]},${GeranCellRelation[$counter]},${GeranFreqGroupRelation[$counter]},${GeranFrequency[$counter]},${TermPointToENB[$counter]},${SectorCarrier[$counter]},${RetSubUnit[$counter]},${TotalMO[$counter]}" | tee -a "$summary_file" 

counter=$[counter+1]

done

EUtranCellFDD=`echo "${EUtranCellFDD[@]/%/+}0" | bc`
EUtranCellRelation=`echo "${EUtranCellRelation[@]/%/+}0" | bc`
EUtranFreqRelation=`echo "${EUtranFreqRelation[@]/%/+}0" | bc`
ExternalENodeBFunction=`echo "${ExternalENodeBFunction[@]/%/+}0" | bc`
ExternalEUtranCellFDD=`echo "${ExternalEUtranCellFDD[@]/%/+}0" | bc`
UtranCellRelation=`echo "${UtranCellRelation[@]/%/+}0" | bc`
UtranFreqRelation=`echo "${UtranFreqRelation[@]/%/+}0" | bc`
ExternalUtranCellFDD=`echo "${ExternalUtranCellFDD[@]/%/+}0" | bc`
GeranCellRelation=`echo "${GeranCellRelation[@]/%/+}0" | bc`
GeranFreqGroupRelation=`echo "${GeranFreqGroupRelation[@]/%/+}0" | bc`
GeranFrequency=`echo "${GeranFrequency[@]/%/+}0" | bc`
TermPointToENB=`echo "${TermPointToENB[@]/%/+}0" | bc`
SectorCarrier=`echo "${SectorCarrier[@]/%/+}0" | bc`
RetSubUnit=`echo "${RetSubUnit[@]/%/+}0" | bc`
TotalMO=`echo "${TotalMO[@]/%/+}0" | bc`

echo "Total,$EUtranCellFDD,$EUtranCellRelation,$EUtranFreqRelation,$ExternalENodeBFunction,$ExternalEUtranCellFDD,$UtranCellRelation,$UtranFreqRelation,$ExternalUtranCellFDD,$GeranCellRelation,$GeranFreqGroupRelation,$GeranFrequency,$TermPointToENB,$SectorCarrier,$RetSubUnit,$TotalMO" | tee -a "$summary_file" 

cleanUp

########
# END
########
