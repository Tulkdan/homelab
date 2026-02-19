FROM rust:latest

RUN cargo install cookcli

WORKDIR /recipes

EXPOSE 9080

CMD ["cook", "server", "--host"]
