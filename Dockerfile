FROM oven/bun:1 as bun-base
FROM --platform=linux/amd64 afonsopc/holy-c as holy-base

FROM holy-base AS build-holy

WORKDIR /code
COPY jokes-manager/Main.HC ./file.HC
RUN hcc ./file.HC
RUN mv a.out /jokes


FROM bun-base AS bun-build

WORKDIR /code
COPY jokes-api/ .
RUN bun install --frozen-lockfile --production


FROM debian:trixie-slim as execute

ENV JOKES_BINARY "/app/bin/jokes.sh"
ENV PORT "3000"
ENV MAX_STRING_LENGTH "255"
ENV JOKES_DB_PATH "/app/database/jokes.db"

RUN apt-get update ; apt-get upgrade -y
RUN apt-get install -y curl unzip

RUN if [ "$(uname -m)" != "x86_64" ]; then \
      apt-get install -y qemu-user; \
    fi

# Install bun
RUN useradd -m user
USER user
WORKDIR /home/user
RUN curl https://bun.sh/install -o install-bun.sh
RUN chmod +x install-bun.sh
RUN ./install-bun.sh
USER root
RUN rm install-bun.sh
RUN mv /home/user/.bun/bin/bun /usr/bin/bun
RUN userdel user
RUN rm -rf /home/user

WORKDIR /app

# Create the database directory
RUN mkdir -p ${JOKES_DB_PATH}
RUN rm -rf ${JOKES_DB_PATH}

COPY --from=build-holy /jokes /app/bin/jokes
COPY --from=bun-build /code/node_modules /app/api/node_modules
COPY --from=bun-build /code/src/ /app/api/src/
COPY --from=bun-build /code/package.json /app/api/package.json

# Create the script to use the jokes binary emulated or if it is x86_64 use the binary
RUN echo "#!/bin/bash" > /app/bin/jokes.sh
RUN echo "if [ \"\$(uname -m)\" != \"x86_64\" ]; then" >> /app/bin/jokes.sh
RUN echo "  qemu-amd64 -L /lib64 /app/bin/jokes" >> /app/bin/jokes.sh
RUN echo "else" >> /app/bin/jokes.sh
RUN echo "  /app/bin/jokes" >> /app/bin/jokes.sh
RUN echo "fi" >> /app/bin/jokes.sh
RUN chmod +x /app/bin/jokes.sh

# Copy the lib64 directory
COPY jokes-manager/lib64 /lib64

WORKDIR /app/api

CMD ["bun", "run", "start"]