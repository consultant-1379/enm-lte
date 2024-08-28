#!/bin/sh
### VERSION HISTORY
#####################################################################################
# Version1    : Created for SimNet Improvement Programme
# Purpose     : Generate log of build errors
# Description :	Generate log of build errors for each build so that error logs arei
#               in one place
# Date        : 09 September 2014
# Who         : ebildun
######################################################################################
# Version2    : LTE 15B
# Revision    : CXP 903 0491-141-1
# Purpose     : Generate new ext n/w files for new MULTISIMS.env configs
# Description : Ignore errors with the term 'already' 
# Date        : 21/04/2015
# Who         : edalrey
######################################################################################
# Version3    : 16.6
# Revision    : CXP 903 0491-204-1
# Jira        : NSS-2548
# Purpose     : enable support for simulation build summary log 
# Description : simulation build summary log generated for each simulation,logs errors, 
#               server name, NETSim version and installed NETSim patches
# Date        : March 2016
# Who         : ejamfur
######################################################################################
######################################################################################
# Version4    : LTE 17.5
# Revision    : CXP 903 0491-287-1
# JIRA        : NSS-10178
# Purpose     : LTE code base to be updated
# Description : createlogfile:path="/c/logfiles/troubleshooting/error/",logname = "error.log";
#               needs to be by-passed from error check
# Date        : Feb 2017
# Who         : xkatmri
######################################################################################
######################################################################################
# Version5    : LTE 18.6
# Revision    : CXP 903 0491-332-1
# JIRA        : NSS-17417
# Purpose     : Update error check to find Netsim crashes in LTE sim build
# Description : Detect netsim crahes and record it in logs
# Date        : Mar 2018
# Who         : xkatmri
######################################################################################
######################################################################################
# Version5    : LTE 18.7
# Revision    : CXP 903 0491-333-1
# JIRA        : NSS-17696
# Purpose     : Update error check to validate Topology data in LTE sim build
# Description : Detect invalid eutran cell and relations data in Topology file
# Date        : Mar 2018
# Who         : xharidu
######################################################################################
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


# Declare Constants
PWD=$(pwd)
KEYWORD_SEARCH_EXPRESSION="^CREATE-"
LOG_FILE="simulationBuild.log"
LOG_FILE_TEMP="${LOG_FILE}.tmp"
LOG_FILE_HEADING="${LOG_FILE}.heading"
if  [ "$SIMNAME" == " " ]
then
SIMS=($(awk -F "${KEYWORD_SEARCH_EXPRESSION}" 'NF > 1 { print $2}' "${MULTISIM_CONFIG_FILE}"))
else
SIMS=$SIMNAME
fi
SCRIPTS_LOG_PATH="log"
SIM_LOG_FILE="LTE-SIMS.log"
LINES_BEFORE=1
LINES_AFTER=2
KEYWORD_SEARCH_ERROR="error"
KEYWORD_SEARCH_CRASH="crashed"
BASE_PATH="/var/tmp/tep"
NUM_OF_CHARS=135
SCRIPTS_UTILS_PATH="/utils"
UTILS_DIR="utils"

#LTE_VERSION=$(echo ${PWD} | awk -F "${SCRIPTS_UTILS_PATH}" '{ print $1 }' | awk -F "/" '{ print $NF }')

# Declare variables
num_of_sims=0
num_of_errors_in_sim=0
num_of_crashes_in_sim=0
num_of_errors_total=0
num_of_crashes_total=0
problem_with_sim_files="FALSE"
HOST=$(hostname) 
DATE=$(date)
NETSimVersion=$(less /netsim/inst/release.erlang | grep -i "NETSim" | awk -F "*" '{print $2}')
totalNETSimPatches=$(ls /netsim/inst/patches/ | wc -l)
NETSimPatches=$(ls /netsim/inst/patches/ | xargs -n 1 basename)

# Declare Functions
move_file()
{
	# Move a file, if it exists
	if [[ -f ${1} ]]
	then
		mv "${1}" "${1}.save"
		echo "INFO: ${1} moved"
	fi
}

delete_file()
{
	# Delete a file, if it exists
	if [[ -f ${1} ]]
	then
		rm ${1}
		echo "INFO: ${1} removed"
	fi
}

print_char_line()
{
	# Print a line of characters, the number of which is specified by user
	for ((index=1;index<=${2};index++))
	do
	echo -n "${1}"
	done
	echo ""
}

print_stats()
{
	# Print the statistics of the checkForBuildErrors report
	print_line_message "15" "STATS" "${1}"
	print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
	echo "INFO: Total number of errors: ${num_of_errors_total}" >> "${1}"
	print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
        echo "INFO: Total number of crashes: ${num_of_crashes_total}" >> "${1}"
        print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
	echo "INFO: Total number of simulation logs checked: ${num_of_sims}" >> "${1}"
	print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
	echo "" >> "${1}"
}

print_build_server_info()
{
        # Print the statistics of the checkForBuildErrors report
        print_line_message "20" "BUILD SERVER INFO" "${1}"
        print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
        echo "BUILD SERVER: ${HOST}" >> "${1}"
        print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
        echo "DATE/TIME: ${DATE}" >> "${1}"
        print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
        if [ "$SIMNAME" != " " ]      
        then
		echo "SIM NAME: ${SIMNAME}" >> "${1}"
        	print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
	fi
        echo "NETSim version: ${NETSimVersion}" >> "${1}"
        print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
        echo "NETSim Patches: ${totalNETSimPatches}" >> "${1}"
        print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
        if [ $totalNETSimPatches > 0 ]
        then
		for patch in $NETSimPatches; do
                patchInfo=$(less /netsim/inst/patches/$patch/patch_info | grep -i "patch" )
        	echo "${patchInfo}" >> "${1}"
        	print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
		done
	fi
        echo "" >> "${1}"
}

print_stats_old()
{
	# Print the statistics of the checkForBuildErrors report
	print_char_line "#" "15" >> "${1}"
	echo "# Build STATS " >> "${1}"
	print_char_line "#" "15" >> "${1}"
	echo "" >> "${1}"
	print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
	echo "INFO: Total number of errors: ${num_of_errors_total}" >> "${1}"
        print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
        echo "INFO: Total number of crashes: ${num_of_crashes_total}" >> "${1}"
	print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
	echo "INFO: Total number of simulation logs checked: ${num_of_sims}" >> "${1}"
	print_char_line "#" "${NUM_OF_CHARS}" >> "${1}"
	echo "" >> "${1}"
}

print_line_message()
{
	# Print a line message to the checkForBuildErrors report
	print_char_line "#" "${1}" >> "${3}"
	echo "# ${2} " >> "${3}"
	print_char_line "#" "${1}" >> "${3}"
	echo "" >> "${3}"
}

find_lte_version()
{
	# Find the name of the LTE Version
	CURRENT_DIR=$(echo ${PWD} | awk -F "/" '{ print $NF }')
	if [[ "${CURRENT_DIR}" = "${UTILS_DIR}" ]]
	then
		LTE_VERSION=$(echo ${PWD} | awk -F "${SCRIPTS_UTILS_PATH}" '{ print $1 }' | awk -F "/" '{ print $NF }')
	else
		echo "INFO: Problems determining LTE version - script should be in ${UTILS_DIR} directory"
		exit
	fi
}

################################
# MAIN
################################

# Call the function that gets the LTE Version of the current build script
find_lte_version

# Call the function that deletes a file, if it exists
delete_file "${LOG_FILE_HEADING}"
delete_file "${LOG_FILE_TEMP}"

# call the function that copies the log file
echo "INFO: Making backup copy of log file, if it exists ..."
move_file "${LOG_FILE}"

echo "INFO: Generating list of simulations from MULTISIMS file ..."
echo "INFO: Checking log files of listed simulations for errors ..."
print_line_message "29" "ERRORS AND CRASHES" "${LOG_FILE}"
for sim in "${SIMS[@]}"
do
	print_char_line "#" "${NUM_OF_CHARS}" >> "${LOG_FILE}"
	if [[ -f "${BASE_PATH}/${sim}/${LTE_VERSION}/${SCRIPTS_LOG_PATH}/${SIM_LOG_FILE}" ]]
	then
                num_of_errors_in_sim=$(grep -iv "/c/logfiles/troubleshooting/error\|already" "${BASE_PATH}/${sim}/${LTE_VERSION}/${SCRIPTS_LOG_PATH}/${SIM_LOG_FILE}" | grep -ci "${KEYWORD_SEARCH_ERROR}")
                num_of_crashes_in_sim=$(grep -iv "/c/logfiles/troubleshooting/error\|already" "${BASE_PATH}/${sim}/${LTE_VERSION}/${SCRIPTS_LOG_PATH}/${SIM_LOG_FILE}" | grep -ci "${KEYWORD_SEARCH_CRASH}")
                echo "INFO: Simulation log file ${BASE_PATH}/${sim}/${LTE_VERSION}/${SCRIPTS_LOG_PATH}/${SIM_LOG_FILE} has ${num_of_errors_in_sim} errors and ${num_of_crashes_in_sim} crashes" >> "${LOG_FILE}"
		if [ ${num_of_errors_in_sim} -gt 0 ] || [ ${num_of_crashes_in_sim} -gt 0 ]
		then
			echo "INFO: Error Details (review simulation log file for FULL details):" >> "${LOG_FILE}"
			echo "" >> "${LOG_FILE}"
                        grep -iv "/c/logfiles/troubleshooting/error\|already" "${BASE_PATH}/${sim}/${LTE_VERSION}/${SCRIPTS_LOG_PATH}/${SIM_LOG_FILE}" | grep -B "${LINES_BEFORE}" -A "${LINES_AFTER}" -i "${KEYWORD_SEARCH_ERROR}"  >> "${LOG_FILE}"
                        grep -iv "/c/logfiles/troubleshooting/error\|already" "${BASE_PATH}/${sim}/${LTE_VERSION}/${SCRIPTS_LOG_PATH}/${SIM_LOG_FILE}" | grep -B "${LINES_BEFORE}" -A "${LINES_AFTER}" -i "${KEYWORD_SEARCH_CRASH}" >> "${LOG_FILE}"
			((num_of_errors_total+=${num_of_errors_in_sim}))
                        ((num_of_crashes_total+=${num_of_crashes_in_sim}))
		fi
	else
		echo "INFO: Simulation log file ${BASE_PATH}/${sim}/${LTE_VERSION}/${SCRIPTS_LOG_PATH}/${SIM_LOG_FILE} was not found" >> "${LOG_FILE}"
		problem_with_sim_files="TRUE"
	fi
	print_char_line "#" "${NUM_OF_CHARS}" >> "${LOG_FILE}"
## Validating Topology File ##
   TopologyFile="/netsim/netsimdir/"$sim"/SimNetRevision/TopologyData.txt"
   if [ -e "$TopologyFile" ]
   then
      CheckCellErrors=`cat $TopologyFile | grep -i ".*-13," |wc -l`
      CheckRelationErrors=`cat $TopologyFile | grep -i ".*=," |wc -l`
      if [ "$CheckCellErrors" -eq "0" ] && [ "$CheckRelationErrors" -eq "0" ]
      then
         echo "INFO: Topology File for $sim is clean"
      else
         echo "INFO: There are errors in the topology file of the sim $sim"
         ((num_of_errors_total++))
      fi
   else
      echo "INFO: Topology File for $sim was not generated"
      ((num_of_errors_total++))
   fi
	((num_of_sims++))
done
echo "" >> "${LOG_FILE}"
print_line_message "10" "EOF" "${LOG_FILE}"

# Print the status and add it to the start of the file
print_build_server_info "${LOG_FILE_HEADING}"
print_stats "${LOG_FILE_HEADING}"
print_line_message "25" "SIMULATION BUILD LOG " "${LOG_FILE_TEMP}"
cat "${LOG_FILE_HEADING}" "${LOG_FILE}" >> "${LOG_FILE_TEMP}"
mv "${LOG_FILE_TEMP}" "${LOG_FILE}"
delete_file "${LOG_FILE_TEMP}"
delete_file "${LOG_FILE_HEADING}"

if [[ ${problem_with_sim_files} = "TRUE" ]]
then
	echo "INFO: Problems detecting simulation file(s)"
fi

if [[ ${num_of_errors_total} -gt 0 ]]
then
	echo "INFO: ${num_of_errors_total} errors detected"
fi

if [[ ${num_of_crashes_total} -gt 0 ]]
then
        echo "INFO: ${num_of_crashes_total} crashes detected"
fi

if [[ ${num_of_errors_total} -eq 0 && ${num_of_crahes_total} -eq 0 && ${problem_with_sim_files} = "FALSE" ]]
then
	echo "INFO: No errors detected"
else
	echo "INFO: Please review log file: ${LOG_FILE}"
fi

echo "INFO: Done"
