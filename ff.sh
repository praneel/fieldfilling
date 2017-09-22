#!/usr/bin/bash
if [[ ($# -lt 2) || ($# -gt 4) ]];
then
echo "Usage : ff <orgalias> <SObjectName> [nb analysed records - default : all] [nb records by batch unit - default : 2000]"
exit
#
fi
if [[ -z $3 ]];
then
nbRec=0
else
nbRec=$3
fi
#
if [[ -z $4 ]];
then
batchSz=2000
else
batchSz=$4
fi
echo Org : $1
echo Object : $2
echo nbRec : $nbRec
echo batchSz : $batchSz
echo "fieldAnalysisBatch fab = new fieldAnalysisBatch('$2',$nbRec);"> myexec
echo "Id theId = Database.ExecuteBatch(fab,$batchSz);" >> myexec
sfdx force:apex:execute -u $1 -f myexec



