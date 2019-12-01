FROM    postgres:alpine
COPY    *.sql /docker-entrypoint-initdb.d/
VOLUME  /var/lib/postgresql/data
ENV     POSTGRES_USER=gitdb
ENV     POSTGRES_PASSWORD=senha
ENV     POSTGRES_DB=gitdb
ENV     POSTGRES_ROLE=gitdb
