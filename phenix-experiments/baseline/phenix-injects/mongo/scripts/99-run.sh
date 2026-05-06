#!/bin/bash 

# wait for mongo service to boot up
echo "Running 99-run.sh for monogo setup " > /var/log/99-run.log
sleep 10

mongosh admin --eval '

db.createUser(
   {
     user: "root",
     pwd: "example",
     roles: [ "dbOwner" ]
   }
)'

