#!/bin/sh

#
##############################################################################
##     File Name    : Script_to_UpdatIp.sh
##     Author       : Siva Mogilicharla
##     Description  : This will update the ips count in simulation folder
##     Date Created : 10 February 2022
##     Usage        : sh Script_to_UpdatIp.sh <Sim name>
####################################################################################

echo "   "
echo "Running python script for Updating IP values on  : "

sim=$1
switchRV=$2

cd ../bin/Updating_IPs/

sudo -s <<EOF

chmod 777 *

python new_updateip.py -deploymentType mediumDeployment -release 22.03 -simLTE $sim -simWRAN NO_NW_AVAILABLE -simCORE NO_NW_AVAILABLE  -switchToRv $switchRV -IPV6Per yes -docker no

echo "  "
echo "Set_to_UpdateIp.sh script is Completed..."
echo "  "
EOF

