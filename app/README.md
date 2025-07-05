# Docker compose build

```bash
docker compose up -d

docker compose ps

# View all logs
docker compose logs

# View specific service logs (or in realtime by adding -f)
docker compose logs db
docker compose logs app
docker compose logs web 

# Check if web server responds
curl http://localhost:8080
```

## Tests

```bash
# Check if database is accessible
docker compose exec db mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW DATABASES;"

# Check PHP-FPM status
docker compose exec app php -v

# Check nginx configuration
docker compose exec web nginx -t

# Check network connectivity
docker compose exec app ping db
```

## Clean up

```bash
# Stop containers
docker compose down

# Remove volumes (if you want to start fresh)
docker compose down -v
```
