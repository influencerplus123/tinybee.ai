docker run -d --name pybossa-db \
        -e POSTGRES_USER=pybossa \
        -e POSTGRES_PASSWORD=supersecretpassword \
        -e PGDATA=/data/pgdata\
        -v /home/ubuntu:/data \
        postgres:9.6-alpine

docker run --rm -it \
        --link pybossa-db:db    \
  	-e POSTGRES_URL="postgresql://pybossa:supersecretpassword@db/pybossa" \
        asr-mturk/v1.0 \
	python cli.py db_create

docker run -d --name redis-master redis:3.0-alpine
docker run -d --name redis-sentinel \
        --link redis-master \
        jvstein/redis-sentinel

docker run -d --name pb-worker \
        --link redis-master \
        --link redis-sentinel \
        --link pybossa-db:db    \
        -e POSTGRES_URL="postgresql://pybossa:supersecretpassword@db/pybossa" \
        asr-mturk/v1.0 \
        python app_context_rqworker.py scheduled_jobs super high medium low email maintenance

docker run -d --name pybossa \
        --link redis-master \
        --link redis-sentinel \
        --link pybossa-db:db    \
        -e POSTGRES_URL="postgresql://pybossa:supersecretpassword@db/pybossa" \
        -p 8080:8080 \
        asr-mturk/v1.0 

