# infraestructure

Infraestructura local compartida por los microservicios:

- [client-microservice](https://github.com/tareas-practicas-wipay/client-microservice): gestión de clientes
- [merchant-microservice](https://github.com/tareas-practicas-wipay/merchant-microservice): gestión de comercios (merchants)

Levanta una instancia de **DynamoDB Local** con Docker y crea automáticamente la tabla única `MainTable` que utilizan los dos microservicios.

## Servicios

| Servicio | Imagen | Puerto | Descripción |
|---|---|---|---|
| `dynamodb-local` | `amazon/dynamodb-local` | `8000` | Base de datos DynamoDB en local. Los datos se guardan en `docker/dynamodb/`. |
| `dynamodb-init` | `amazon/aws-cli` | — | Ejecuta `scripts/create-tables.sh` para crear `MainTable` y termina (`Exited (0)`). |

## Cómo levantarlo

Desde la raíz de este repositorio:

```
docker compose up -d
```

> `-d` (*detached*) ejecuta los contenedores en segundo plano.

Comprobar que DynamoDB Local está en marcha:

```
docker ps
```

Comprobar que la tabla se ha creado:

```
docker compose logs dynamodb-init
```

La primera vez muestra la descripción de la tabla y `Tabla MainTable creada`. Las siguientes, `La tabla MainTable ya existe`.

### Otros comandos útiles

| Comando | Qué hace |
|---|---|
| `docker compose stop` | Detiene los contenedores sin borrarlos. Los datos se conservan. |
| `docker compose down` | Detiene y elimina los contenedores. Los datos se conservan en `docker/dynamodb/`. |
| `docker compose up -d --remove-orphans` | Levanta los servicios y elimina contenedores de servicios que ya no están en el compose. |

## Diseño de `MainTable`

Clientes y merchants se guardan en la misma tabla y se distinguen por el valor de sus claves.

### Clave primaria

**PK** (Partition key) y **SK** (Sort key)

### Índice secundario global `gIndex2`


### Ejemplo de datos

| PK | SK | gIndex2Pk | keywordsSearch |
|---|---|---|---|
| `CLIENT#c1` | `CLIENTDATA` | `CLIENTEMAIL#info@wipay.com` | Wipay |
| `CLIENT#c1` | `MERCHANT#m1` | `MERCHANT#m1` | Tienda Pepe |
| `CLIENT#c1`  | `MERCHANT#m2`  | `MERCHANT#m2` | Banco Pepe   |
| `CLIENT#c2`  | `CLIENTDATA`   | `CLIENTEMAIL#hola@paypal.com`   | Paypal |

## ¿Por qué un script para crear la tabla?

DynamoDB Local arranca **vacío**, sin ninguna tabla, y los microservicios necesitan que `MainTable` exista.

Crear la tabla a mano no deja constancia en ningún sitio: si se borra `docker/dynamodb/`, se cambia de equipo o alguien clona el repositorio, hay que volver a crearla con las mismas claves y el mismo índice, y es fácil equivocarse.

El script `scripts/create-tables.sh`:

1. **Espera** a que DynamoDB Local acepte peticiones. `depends_on` solo garantiza que el contenedor ha arrancado, no que esté listo.
2. **Es idempotente**: si la tabla ya existe, no hace nada.
3. **Crea** la tabla con su clave primaria y el índice `gIndex2`.

Así la infraestructura es **reproducible**: el mismo comando da siempre el mismo resultado en cualquier equipo.

> **ADVERTENCIA:** El script debe guardarse con saltos de línea `LF`, porque se ejecuta en Linux dentro del contenedor. El fichero `.gitattributes` lo garantiza en Git.
> 
> En IntelliJ, en la parte inferior derecha, cambiar de `CRLF` a `LF` y hacer commit.

## Conexión a la base de datos

| Desde | Endpoint |
|---|---|
| Tu máquina (microservicios, IntelliJ, NoSQL Workbench) | `http://localhost:8000` |
| Otro contenedor de este `docker-compose` | `http://dynamodb-local:8000` |

- **Región:** `eu-west-1`
- **Credenciales:** cualquier valor (por ejemplo, `local` / `local`). DynamoDB Local no las valida.

DynamoDB Local se ejecuta con la opción `-sharedDb`, así que **todos los clientes ven la misma base de datos**, aunque usen credenciales o regiones distintas.

## Herramientas para consultar los datos

### IntelliJ IDEA

1. Abrir el panel lateral **DynamoDB**.
2. Añadir una conexión local con endpoint `http://localhost:8000` y región `eu-west-1`.
3. Refrescar para ver `MainTable` y su índice `gIndex2`.

### NoSQL Workbench

1. **Operation builder → Add connection → DynamoDB local**.
2. Hostname `localhost`, puerto `8000`.

> NoSQL Workbench incluye su propio DynamoDB Local (interruptor *DDB local*), que también usa el puerto `8000`. **Debe estar desactivado**: si no, entra en conflicto con el contenedor de Docker.

