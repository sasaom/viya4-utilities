#! /bin/bash

inputfilename=$1

if [[ ! -f $inputfilename ]]
then 
    echo "**ERROR** Cannot find inputfile: $inputfilename"
    exit 1
fi

echo "Removing quotes from values"
sed -i 's/\"//g' $inputfilename
echo "done"
while IFS="," read -r podname containername sasclass nodename cpurequest memrequest cpulimit memlimit 
do
  if [[ $cpulimit =~ "m" ]]; then
    newcpulimit=$(echo $cpulimit | sed 's/[^0-9]*//g')
  else
    newcpulimit=$(( cpulimit*1000 ))
  fi
  if [[ $cpurequest =~ "m" ]]; then
    newcpurequest=$(echo $cpurequest | sed 's/[^0-9]*//g')
  else
    newcpurequest=$(( cpurequest*1000 ))
  fi
  echo $podname,$sasclass,$nodename,$newcpulimit,$newcpurequest,$memlimit,$memrequest
done < $inputfilename