FROM postgres:13

COPY init.sql /docker-entrypoint-initdb.d/
ENV POSTGRES_DB=retail_db
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres