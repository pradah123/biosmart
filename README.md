# biosmart-api

Application serving api using BioSmart data

## Prerequisite
- Docker
- Redis container running within biosmart-net
```
docker run -d --name biosmart-redis --net biosmart-net -v /Users/codetoart/work/docker/biosmart-redis-data:/data  redis:6.2.6-bullseye redis-server --save 60 1 --loglevel warning
```
- Postgres container running within biosmart-net
```
docker run -d --name biosmart-db -v biosmart-db-volume:/var/lib/postgresql/data -e POSTGRES_DB=biosmart_db -e POSTGRES_USER=dbuser -e POSTGRES_PASSWORD=dbpasswd --net biosmart-net postgis/postgis
```

## Getting started

```
git clone https://gitlab.com/earthguardians1/biosmart-api.git
cd biosmart-api
docker rm biosmart-api;docker build -t biosmart-api -f docker/app.Dockerfile .;docker run --name biosmart-api --env-file=.env -p 8080:8080 --net biosmart-net biosmart-api
```
## .env file sample
```
DB_USER=dbuser
DB_PASSWORD=dbpasswd
DB_HOST=biosmart-db
DB_NAME=biosmart_db
RACK_ENV=development
REDIS_URL=redis://biosmart-redis:6379/0
RAYGUN_API_KEY=<API-KEY>

```
## Sample output
```
Puma starting in single mode...
* Puma version: 5.6.2 (ruby 3.0.2-p107) ("Birdie's Version")
*  Min threads: 5
*  Max threads: 5
*  Environment: development
*          PID: 1
* Listening on http://0.0.0.0:8080
Use Ctrl-C to stop
```
## Verifying API
```
http://localhost:8080/api/status

{"status":"healthy"}
```
