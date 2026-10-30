#!/bin/sh
N="${1:-500}"
i=0
while [ "$i" -lt "$N" ]; do
  curl -s -o /dev/null -H "Host: api.localhost" http://localhost/products
  curl -s -o /dev/null -H "Host: api.localhost" -X POST -H "Content-Type: application/json" -d '{"productId":1,"quantity":1}' http://localhost/orders
  curl -s -o /dev/null -H "Host: api.localhost" http://localhost/inexistant
  i=$((i+1))
done
