# Архитектура данных MongoDB для онлайн-магазина «Мобильный мир»

## 1. Назначение документа

Описание схем коллекций для онлайн-магазина «Мобильный мир», используемых в системе.

---

## 2. Область применения

- Проект: Онлайн-магазин «Мобильный мир»
- Окружение: `prod`
- Версия документа: `1.0`

---

## 3. Описание коллекций
«Мобильный мир» хранит информацию о заказах, товарах и корзинах в трёх коллекциях в MongoDB.
### 3.1 Коллекция: orders
#### JSON схема
```json
{
  "$jsonSchema": {
    "bsonType": "object",
    "required": ["customerId", "items", "totalAmount", "geoZone"],
    "properties": {
      "_id": {
        "bsonType": "objectId",
        "description": "Уникальный идентификатор заказа"
      },
      "customerId": {
        "bsonType": "string",
        "description": "Идентификатор пользователя"
      },
      "orderDate": {
        "bsonType": "date",
        "description": "Дата и время оформления заказа"
      },
      "items": {
        "bsonType": "array",
        "description": "Список товаров в заказе",
        "minItems": 1,
        "items": {
          "bsonType": "object",
          "required": ["productId", "quantity", "price"],
          "properties": {
            "productId": {
              "bsonType": "objectId",
              "description": "Ссылка на товар в каталоге"
            },
            "quantity": {
              "bsonType": "int",
              "minimum": 1,
              "description": "Количество единиц товара"
            },
            "price": {
              "bsonType": "number",
              "minimum": 0,
              "description": "Цена товара на момент оформления заказа"
            },
            "name": {
              "bsonType": "string",
              "description": "Название товара"
            },
            "category": {
              "bsonType": "string",
              "description": "Категория товара"
            }
          }
        }
      },
      "status": {
        "enum": ["pending", "processing", "shipped", "delivered", "cancelled"],
        "description": "Текущий статус заказа"
      },
      "totalAmount": {
        "bsonType": "number",
        "minimum": 0,
        "description": "Общая стоимость заказа"
      },
      "geoZone": {
        "bsonType": "string",
        "description": "Географическая зона оформления и доставки"
      },
      "created_at": {
        "bsonType": "date",
        "description": "Дата создания заказа"
      },
      "updated_at": {
        "bsonType": "date",
        "description": "Дата последнего изменения заказа"
      }
    }
  }
}
```

### Индексы 
```js
{ customerId: 1, orderDate: -1 } - для быстрого поиска истории заказов пользователя 
```

### Shard-ключи

Выбранный shard key: user_id hashed

Преимущества: Высокая кардинальность, равномерное распределение записей. Все заказы пользователя на одном шарде — ускоряет историю заказов.
### 3.2 Коллекция: products
#### JSON схема
```json
{
  "$jsonSchema": {
    "bsonType": "object",
    "required": ["name", "category", "price"],
    "properties": {
      "_id": {
        "bsonType": "objectId",
        "description": "Уникальный идентификатор товара"
      },
      "name": {
        "bsonType": "string",
        "description": "Наименование товара"
      },
      "category": {
        "bsonType": "string",
        "description": "Категория товара"
      },
      "price": {
        "bsonType": "number",
        "minimum": 0,
        "description": "Цена товара"
      },
      "stock": {
        "bsonType": "object",
        "description": "Остатки товара по географическим зонам",
        "additionalProperties": {
          "bsonType": "int",
          "minimum": 0,
          "description": "Количество товара в конкретной геозоне"
        }
      },
      "attributes": {
        "bsonType": "object",
        "description": "Произвольные атрибуты товара"
      },
      "created_at": {
        "bsonType": "date",
        "description": "Дата создания записи о товаре"
      },
      "updated_at": {
        "bsonType": "date",
        "description": "Дата последнего обновления товара"
      }
    }
  }
}
```

### Индексы
```js
{ category: 1, price: 1 } - для быстрого поиска товаров по категориям и фильтрация по диапазону цен.
```

### Shard-ключи

Выбранный shard key: category hashed
Преимущества: пользователи часто просматривают одну категорию полностью — все данные категории находятся на одном шарде.

### 3.3 Коллекция: carts
#### JSON схема
```json
{
  "$jsonSchema": {
    "bsonType": "object",
    "required": ["items", "status"],
    "properties": {
      "_id": {
        "bsonType": "objectId",
        "description": "Уникальный идентификатор корзины"
      },
      "user_id": {
        "bsonType": "string",
        "description": "Идентификатор авторизованного пользователя"
      },
      "session_id": {
        "bsonType": "string",
        "description": "Идентификатор сессии гостя"
      },
      "items": {
        "bsonType": "array",
        "description": "Список товаров в корзине",
        "items": {
          "bsonType": "object",
          "required": ["product_id", "quantity"],
          "properties": {
            "product_id": {
              "bsonType": "objectId",
              "description": "Ссылка на товар в каталоге"
            },
            "quantity": {
              "bsonType": "int",
              "minimum": 1,
              "description": "Количество товара в корзине"
            }
          }
        }
      },
      "status": {
        "enum": ["active", "ordered", "abandoned"],
        "description": "Состояние корзины"
      },
      "created_at": {
        "bsonType": "date",
        "description": "Дата создания корзины"
      },
      "updated_at": {
        "bsonType": "date",
        "description": "Дата последнего обновления корзины"
      },
      "expires_at": {
        "bsonType": "date",
        "description": "Дата автоматического удаления корзины (TTL)"
      }
    }
  }
}

```

### Индексы
```js
{ session_id: 1, status: 1 }: Для получения активной корзины гостей
{ user_id: 1, status: 1 }: Для получения активной корзины пользователей
```

### Shard-ключи

Выбранный shard key: _id hashed
Преимущества: Равномерное распределение, высокая кардинальность.


## 4.1 Набор метрик мониторинга

| Метрика | Описание | Источник                                             |
|---------|----------|------------------------------------------------------|
| Размер данных на шарде  | Отражает текущий объём данных на каждом шарде для sharded коллекций. Ключевая метрика для оценки равномерности распределения данных и выявления потенциальных узких мест. | `sh.status()`, `db.collection.stats()`               |
| Количество чанков на шарде | Показывает распределение чанков данных по всем шардом. Позволяет выявить дисбаланс, который может привести к перегрузке отдельных шардов. | `sh.status()`                                        |
| Активность миграций чанков | Фиксирует количество и частоту перемещений чанков между шардами. Помогает отслеживать работу балансировщика и выявлять аномальные паттерны нагрузки. | Логи балансировщика, `sh.balancerCollectionStatus()` | 
| Средний размер объекта | Средний размер документов в коллекции. Важен для расчёта лимита чанка и предотвращения блокировки миграций. | `db.collection.stats()`                              | 
| Объем данных по коллекциям | Общий объём данных на каждом шарде с учётом всех коллекций. Позволяет оценить нагрузку на конкретный шард и планировать перераспределение данных. |
| Использование CPU и памяти| Отражает загрузку процессора и RAM на узлах шардов. Важная метрика для выявления узких мест по вычислительным ресурсам и предотвращения деградации производительности. | `serverStatus`, инструменты ОС (`top`, `htop`) | 

## 4.2 Механизмы автоматического перераспределения данных

1. Встроенный Balancer:
Описание: Фоновый процесс, мигрирующий чанки с перегруженных шардов.
Пример настройки:
```js
sh.setBalancerState(true); 
sh.setBalancerWindow({ start: "00:00", stop: "06:00" });  
```

2. Tag-Aware Sharding:
Описание: Распределение по зонам (тегами) для изоляции горячих данных.
```js
sh.addShardTag("shard001", "high-traffic");  
sh.addTagRange("db.products", { category: "Электроника" }, { category: "Электроника\xff" }, "high-traffic"); 
```

3. Chunk Splitting и Resharding:
Описание: Разбиение чанков и перешардирование для адаптации.
```js 
sh.splitAt("db.products", { category: "Электроника", _id: ObjectId("...") });  
db.adminCommand({ reshardCollection: "db.products", key: { category: 1, geo_zone: 1 } }); 
```

## 5. Настройка чтения с реплик и консистентность
#### Коллекция products (Товары)

Операции чтения на secondary:
Поиск товаров по категориям и фильтрация по диапазону цен (e.g., db.products.find({ category: "Электроника", price: { $gte: 1000, $lte: 50000 } })).
Описание товара на странице продукта (e.g., db.products.findOne({ _id: ObjectId("...") })), если не проверяются остатки.

Операции чтения только на primary:
Чтение остатков перед добавлением в корзину или покупкой (e.g., db.products.findOne({ _id: ObjectId("...") }, { stock: 1 })), чтобы избежать продажи отсутствующего товара.

Допустимая задержка репликации: до 10 секунд 
#### Коллекция orders (Заказы)

Операции чтения на secondary:
Поиск истории заказов конкретного пользователя (e.g., db.orders.find({ user_id: ObjectId("...") }).sort({ created_at: -1 })), нет критичности

Операции чтения только на primary:
Отображение статуса заказа (e.g., db.orders.findOne({ _id: ObjectId("...") }, { status: 1 })), чтобы пользователь видел актуальный статус (не устаревший из-за lag).

Допустимая задержка репликации: до 30 секунд для истории. 

#### Коллекция carts (Корзины)

Операции чтения на secondary:
Получение текущей корзины по session_id или user_id (e.g., db.carts.findOne({ session_id: "abc123", status: "active" })), для отображения содержимого.

Операции чтения только на primary:
Чтение корзины перед слиянием гостевой и пользовательской или перед оформлением заказа (e.g., db.carts.findOne({ user_id: ObjectId("..."), status: "active" })), чтобы избежать конфликтов.

Допустимая задержка репликации: до 10 секунд.


## 6.1 Cassandra
Данные, для которых Cassandra имеет смысл:

Корзины (carts) и пользовательские сессии:
Обоснование:
- Обеспечивает высокую доступность, если один или несколько узлов упадут запись в корзину не прекратится.
- Высокая скорость записи. Основной сценарий - добавление новых товаров в корзину 
- Eventual consistency — допустима для корзины
- TTL  — встроенная функциональность

## 6.2 Модель данных в Cassandra

Partition Key: cart_id - равномерное распределение по шардам
Каждый узел знает, где находится каждая корзина по её cart_id

```cql
CREATE TABLE carts (
cart_id uuid PRIMARY KEY,     
user_id uuid,
session_id uuid,
items list<frozen<tuple<uuid, int>>>,
status text,
created_at timestamp,
updated_at timestamp,
expires_at timestamp
);
```
Partition Key: (user_id/session_id, status) - все активные корзины пользователя/сессии в одной партиции, быстрый доступ к данным 
```cql
CREATE TABLE carts_by_user_status (
    user_id uuid,
    status text,
    cart_id uuid,
    created_at timestamp,
    expires_at timestamp,
    PRIMARY KEY ((user_id, status), created_at, cart_id)
) WITH CLUSTERING ORDER BY (created_at DESC)
   AND default_time_to_live = 604800;
```

```cql
CREATE TABLE carts_by_session_status (
    session_id uuid,
    status text,
    cart_id uuid,
    created_at timestamp,
    expires_at timestamp,
    PRIMARY KEY ((session_id, status), created_at, cart_id)
) WITH CLUSTERING ORDER BY (created_at DESC)
   AND default_time_to_live = 604800;
```

## 6.3 Выбор стратегии для обеспечения целостности данных

Для carts подходит использование Hinted Handoff + Read Repair
- Hinted Handoff
Корзины меняются часто(добавление, удаление товаров). Стратегия hinted handoff обеспечивает высокую доступность — система не отказывает в записи, даже если часть машин не работает.
- Read Repair
Корзины часто просматриваются пользователями. Это помогает ловить расхождения и синхронизировать узлы автоматически.

Комбинация двух механизмов позволяет быстро синхронизировать узлы при кратковременных сбоях с помощью hinted handoff, 
но если подсказа по какой-либо причине была потеряна, данные синхронизируются с помощью Read Repair во время чтения.
