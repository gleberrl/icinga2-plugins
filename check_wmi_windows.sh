#!/bin/sh

################################# check_wmi_windows.sh ###########################
# Version : 1.0                                                                  #
# Date : 22 May 2018                                                             #
# Author : Gleber Ribeiro Leite (gleberrl@yahoo.com.br)                          #
# Contributor(s):                                                                #
##################################################################################
#                                                                                #
# Help : ./check_wmi_windows.sh -h                                               #
# Dependency:                                                                    #
# wmic -> http://www.openvas.org/download/wmi/wmi-1.3.14.tar.bz2                 #
##################################################################################

#Declare variables
domain="0"
critical=0
username=""
password=""
TYPE="iispool"

#Create argument(s)
while getopts ":hH:D:P:t:n:U:" optname
        do
                case "$optname" in
                        "h")
                                printf "\nUsage: check_wmi_windows.sh -H [IP ADDRESS] -D [DOMAIN NAME] -U [USERNAME] -P [PASSWORD] -t [IISPOOL(default)/SERVICE] -n [IIS POOL NAME/SERVICE NAME]\n\n"
                                exit
                        ;;
                        "H")
                                ip=$OPTARG
                        ;;
                        "D")
                                domain=$OPTARG
                        ;;
                        "U")
                                username=$OPTARG
                        ;;
                        "P")
                                password=$OPTARG
                        ;;
                        "t")
                                TYPE=$OPTARG
                        ;;
                        "n")
                                NAME=$OPTARG
                        ;;
                        \?)
                                printf "\nUnknown option argument: \"-$OPTARG\"\nMore info with \"check_wmi_windows.sh -h\"\n\n" >&2
                                exit 2;
                        ;;
                esac
        done
	TYPE=`echo $TYPE | tr '[a-z]' '[A-Z]'`
        name=`echo $NAME | tr '[a-z]' '[A-Z]'`
#Check the required argument(s)

if [[ $domain != "0"  &&  $username != "" && $password != "" && $TYPE == "IISPOOL" && $NAME != "" ]]; then
        NAME_RESULT=`wmic -U $domain/$username%$password //$ip "SELECT CurrentApplicationPoolState FROM Win32_PerfFormattedData_APPPOOLCountersProvider_APPPOOLWAS WHERE Name='$NAME'" | grep $NAME | cut -d"|" -f1`

elif [[ $domain != "0"  &&  $username != "" && $password != "" && $TYPE == "SERVICE" && $NAME != "" ]]; then
        STATUS_SERVICE_RESULT=`wmic -U $domain/$username%$password //$ip "SELECT Status FROM Win32_Service WHERE Caption='$NAME'" | sed -n 3p | cut -d"|" -f2`
        STATE_SERVICE_RESULT=`wmic -U $domain/$username%$password //$ip "SELECT State FROM Win32_Service WHERE Caption='$NAME'" | sed -n 3p | cut -d"|" -f2`

else #output when no arguments
        printf "\nUsage: check_wmi_windows.sh -h \n\n"
        exit 1;
fi

#Possibles outputs
if [[ $TYPE == "IISPOOL" ]]; then
	if [[ $NAME_RESULT == 3 ]]; then
        	echo "OK; Pool $name is UP. Exit Code $NAME_RESULT."
	        exit 0;

	elif [[ $NAME_RESULT != 3 ]]; then
	        echo "CRITICAL; Pool $name is DOWN. Exit Code $NAME_RESULT."
	        exit 2;
	fi
elif [[ $TYPE == "SERVICE" ]]; then
	if [[ $STATUS_SERVICE_RESULT == "OK" && $STATE_SERVICE_RESULT == "Running" ]]; then
	        echo "OK; Service $name is UP. Status=$STATUS_SERVICE_RESULT State=$STATE_SERVICE_RESULT."
	        exit 0;
	else
	        echo "CRITICAL; Service $name is DOWN. Status=$STATUS_SERVICE_RESULT State=$STATE_SERVICE_RESULT."
	        exit 2;
	fi
else
        printf "\nUsage: check_wmi_windows.sh -h \n\n"
        exit 1;
fi
