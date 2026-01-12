#!/bin/bash

###
# Инициализируем бд
###


docker exec -it configSrv mongo --port 27020 --eval 'rs.initiate({ _id: "config_server", configsvr: true, members: [ { _id: 0, host: "173.17.0.10:27020" } ] })'

docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF

#docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
#use somedb
#db.helloDoc.countDocuments()
#EOF