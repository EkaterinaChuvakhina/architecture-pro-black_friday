# sharding-repl-cache

## Как запустить

1. Запуск контейнеров:
```bash
docker compose up -d
```

2. Инициализация конфигурационного сервера и шардов
```bash
docker exec -it configSrv mongosh --port 27020 --eval 'rs.initiate({ _id: "config_server", configsvr: true, members: [ { _id: 0, host: "configSrv:27020" }, { _id: 1, host: "configSrv2:27021" }, { _id: 2, host: "configSrv3:27022" } ] })'
```
```bash
docker exec -it shard1_1 mongosh --port 27018 --eval 'rs.initiate({ _id: "shard1", members: [ { _id: 0, host: "shard1_1:27018" }, { _id: 1, host: "shard1_2:27018" }, { _id: 2, host: "shard1_3:27018" } ] })'
```
```bash
docker exec -it shard2_1 mongosh --port 27019 --eval 'rs.initiate({ _id: "shard2", members: [ { _id: 0, host: "shard2_1:27019" }, { _id: 1, host: "shard2_2:27019" }, { _id: 2, host: "shard2_3:27019" } ] })'
```

3. Добавление шардов в кластер:
```bash
docker exec -it mongos1 mongosh --port 27017 --eval 'sh.addShard("shard1/shard1_1:27018,shard1_2:27018,shard1_3:27018")'
```

```bash
docker exec -it mongos1 mongosh --port 27017 --eval 'sh.addShard("shard2/shard2_1:27019,shard2_2:27019,shard2_3:27019")'
```
4. Включение шардинга и добавление тестовых данных:

```bash
docker exec -it mongos1 mongosh --port 27017 --eval '
db = db.getSiblingDB("somedb");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { name: "hashed" });

for (let i = 0; i < 1000; i++) {
  db.helloDoc.insert({ age: i, name: "ly" + i });
}

db.helloDoc.countDocuments();
'
```
## Как проверить

Проверяем количество документов:

curl http://localhost:8080/helloDoc/count

Проверяем список пользователей:

curl http://localhost:8080/helloDoc/users

## Остановка и очистка окружения
```bash
docker compose down -v
```