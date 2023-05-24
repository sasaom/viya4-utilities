#!/bin/bash

sas-viya auth login -u aomsbe -p Orion123

accounlist=$(sas-viya identities list-users | jq -r '.items[].id')

for account in $accounlist
do
  userid=$(id -u $account)
  groupId=$(id -g $account)
  sas-viya identities update-user --id $account --uid $userid --gid $groupId
done
