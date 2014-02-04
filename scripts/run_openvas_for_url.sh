#!/usr/bin/env bash
#
# Date:    2013-12-30
#
# owtf is an OWASP+PTES-focused try to unite great tools and facilitate pen testing
# Copyright (c) 2011, Abraham Aranguren <name.surname@gmail.com> Twitter: @7a_ http://7-a.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright 
# notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# * Neither the name of the copyright owner nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



URL1=$1

URL=$(echo $URL1 |sed -e 's/^http:\/\///g' -e 's/^https:\/\///g')

CONFIG_ID=$2

PGSAD=$3

DATE=$(date +%F_%R_%S | sed 's/:/_/g')

OUTFILE="OpenVAS_Main_Report_$DATE"

DIR=$(pwd) # Remember current dir
DIR1="$DIR/../../../../../../../"
DIR2="$DIR/../../../../../../../profiles/general/default.cfg"
echo

$DIR1/scripts/openvas_quick_check.sh $PGSAD

PASS=$(grep OPENVAS_PASS $DIR2 | cut -f2 -d' ')

if [[ "$PASS" = "" ]]
then 
$DIR1/scripts/generate_pass_openvas.sh $DIR2
PASS=$(grep OPENVAS_PASS $DIR2 | cut -f2 -d' ')
fi

echo "Runnig OpenVAS Plugin.."

echo  ""
  
#Creating target
TARGET_ID=$(omp -u admin -w $PASS -iX '<create_target><name>'OWTF_Target_$URL'</name><hosts>'$URL'</hosts></create_target>'  | sed 's/  *//g'|cut -f2 -d'"')
  
if [[ $TARGET_ID = *Targetexistsalready* ]]; then
  echo -e "Target already exists\nExiting from OpenVAS.."
  exit
fi

if [ "$TARGET_ID" == "" ]
then
  echo "Authentication Failure"
  exit
fi 
 


echo "#########################################################################"
echo "###                                                                   ### 
###                      __  __  __            __  __                 ###
###                     |  ||__||__ |\ | \  / |__||__                 ###
###                     |__||   |__ | \|  \/  |  | __|                ###
###                                                                   ###
### "

echo "###--------------Target Created : OWTF_Target_$URL..."

#Task creation

TASK_ID=$(omp -u admin -w $PASS --xml="<create_task><name>OWTF_Task_$URL</name>
                                       <config id=\"$CONFIG_ID\"/>
                                       <target id=\"$TARGET_ID\"/>
                    </create_task>" |  sed 's/  *//g'|cut -f2 -d'"')

echo "###-------------------------------------------------------------------###"
echo "###--------------Task Created : OWTF_Task_$URL..."

#getting report id

REPORT_ID=$(omp -u admin -w $PASS --xml="<start_task task_id=\"$TASK_ID\"/>" | sed 's/  *//g'|cut -f3 -d'>' |cut -f1 -d'<')

echo "###-------------------------------------------------------------------###"
echo "###--------------Task Started-----------------------------------------###"

echo "###-------------------------------------------------------------------###"

echo "###--------------Status Check-----------------------------------------###"
echo -e "\n"





STATUS=$(omp -u admin -w $PASS -G | grep $TASK_ID|sed 's/  */#/g'|cut -f2,3 -d'#')

echo "In Progress...Hang tight !!"
echo "(You can check your status of progress by going to http://127.0.0.1:$PGSAD and logging in
with the username 'admin' and the password and then going to tasks tab in scan management)".
while [[ $STATUS != *Done* ]]
do
   #All the below statements were for progress bar.But as that is not yet possible in OWTF,
   #I have kept it for future use.
  
   #tput el1
   #tput rc
   #echo -n "###"
   #echo  "$STATUS"| sed -e "s/#/ /g" |sed -e 's/Task.[0-9]*//g'
   #echo -ne "$STATUS\033[0K\r" | sed -e "s/#/ /g" |sed -e 's/Task.[0-9]*//g'
   #echo  "---------------$STATUS...." | sed -e "s/#/ /g" |sed -e 's/Task.[0-9]*//g'
   
   sleep 1 
   
   STATUS=$(omp -u admin -w $PASS -G | grep $TASK_ID |sed 's/  */#/g'|cut -f2,3 -d'#')
   if [[ $STATUS = *Stopped* ]];then
     break
   fi
done

#deleting the task

omp -u admin -w $PASS --delete-task $TASK_ID

echo -e "\n"
echo -n "###------------------Done !-------------------------------------------###"
echo -e "\n"
echo "###-------------------------------------------------------------------###"
echo "###--------------Status Check Complete--------------------------------###"
echo "###-------------------------------------------------------------------###"

DIR=$(pwd)
echo "###--------------Creating report in $DIR"...

#get report

omp -u admin -w $PASS --get-report $REPORT_ID  --format 6c248850-1f62-11e1-b082-406186ea4fc5  > $OUTFILE.html

echo "###-------------------------------------------------------------------###"
echo "###--------------Report Generated-------------------------------------###"
echo -e "\n"

echo "###----------------- [*] Done!] --------------------------------------###"
echo "#########################################################################"
exit