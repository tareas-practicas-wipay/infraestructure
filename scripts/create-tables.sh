#!/bin/sh
ENDPOINT="http://dynamodb-local:8000"
TABLE="MainTable"

# 1. Esperar a que DynamoDB Local esté listo para aceptar peticiones
until aws dynamodb list-tables --endpoint-url "$ENDPOINT" > /dev/null 2>&1; do
  echo "Esperando a DynamoDB Local..."
  sleep 1
done

# 2. Si la tabla ya existe, no hacer nada (idempotente)
if aws dynamodb describe-table --table-name "$TABLE" --endpoint-url "$ENDPOINT" > /dev/null 2>&1; then
  echo "La tabla $TABLE ya existe"
  exit 0
fi

# 3. Crear la tabla con su clave primaria y el GSI
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions \
      AttributeName=PK,AttributeType=S \
      AttributeName=SK,AttributeType=S \
      AttributeName=gIndex2Pk,AttributeType=S \
  --key-schema \
      AttributeName=PK,KeyType=HASH \
      AttributeName=SK,KeyType=RANGE \
  --global-secondary-indexes '[{
      "IndexName": "gIndex2",
      "KeySchema": [
        {"AttributeName": "gIndex2Pk", "KeyType": "HASH"},
        {"AttributeName": "SK", "KeyType": "RANGE"}
      ],
      "Projection": {"ProjectionType": "ALL"}
    }]' \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url "$ENDPOINT"

echo "Tabla $TABLE creada"