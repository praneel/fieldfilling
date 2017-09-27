#!/bin/bash
#	author : vbrenet@salesforce.com
#
#	ff.sh : launch fieldAnalysisBatch using the sfdx anonymous Apex execution command
#
#	Instructions of use: 
#	sh ff.sh <orgalias> <SObjectName> [nb analysed records - 0 : all] [nb records by batch unit - default : 2000]
#	example 1:  sh ff myorg Opportunity 0 500 : all opportunity records will be analysed, size of batches = 500 records
#	example 2 : sh ff myorg Lead : all Lead records will be analysed, size of batches = 2000 records
#	example 3 :	sh ff myorg Contact 1000 : up to 1000 Contacts records will be analysed, size of batches = 2000 records
#
#	Prerequisites : sfdx up and running, target org registered with sfdx, fieldAnalysisBatch deployed in the target org
#
if [[ ($# -lt 2) || ($# -gt 4) ]];
then
echo "Usage : ff <orgalias> <SObjectName> [nb analysed records - 0 : all] [nb records by batch unit - default : 2000]"
exit
fi

if [[ -z $3 ]];
then
nbRec=0
else
nbRec=$3
fi

if [[ -z $4 ]];
then
batchSz=2000
else
batchSz=$4
fi

echo Org : $1
echo Object : $2
echo Max number of records to be analysed : $nbRec
echo Size of batch units : $batchSz
echo "fieldAnalysisBatch fab = new fieldAnalysisBatch('$2',$nbRec);"> myexec
echo "Id theId = Database.ExecuteBatch(fab,$batchSz);" >> myexec

set -x
sfdx force:apex:execute -u $1 -f myexec



