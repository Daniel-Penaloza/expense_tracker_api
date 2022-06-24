## How to make the requests

##### JSON
```curl -X POST http://localhost:9292/expenses -H "Content-Type: application/json" -d '{"payee": "Store","amount":"345.34","date":"2020-01-01"}'```

##### XML
```curl -X POST http://localhost:9292/expenses -H "Content-Type: text/xml" -d  "<payee>Store</payee><amount>320.90</amount><date>2020-01-01</date>"```
