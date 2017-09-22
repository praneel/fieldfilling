#!/usr/bin/bash
echo scriptname : $0
echo nb param $#
#echo $1
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
echo P1 : $1
echo P2 : $2
echo nbRec : $nbRec
echo batchSz : $batchSz
echo "fieldAnalysisBatch fab = new fieldAnalysisBatch('$2',$nbRec);"
echo "Id theId = Database.ExecuteBatch(fab,$batchSz);"



