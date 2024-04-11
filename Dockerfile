FROM oven/bun:1 as bun-base
FROM --platform=linux/amd64 afonsopc/holy-c as holy-base


FROM debian:trixie-slim as runtime

# Install the necessary dependencies
RUN apt-get update
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


FROM holy-base AS build-holy

WORKDIR /code
COPY jokes-manager/Main.HC ./file.HC
RUN hcc ./file.HC
RUN mv a.out /jokes


FROM bun-base AS bun-build

WORKDIR /code
COPY jokes-api/ .
RUN bun install --frozen-lockfile --production


FROM runtime

ENV JOKES_BINARY "/app/bin/jokes"
ENV PORT "3000"
ENV MAX_STRING_LENGTH "255"
ENV JOKES_DB_PATH "/app/db/jokes.db"

WORKDIR /app

# Create the database directory
RUN mkdir -p ${JOKES_DB_PATH}
RUN rm -rf ${JOKES_DB_PATH}

COPY --from=build-holy /jokes /app/bin/jokes
COPY --from=bun-build /code/node_modules /app/api/node_modules
COPY --from=bun-build /code/src/ /app/api/src/
COPY --from=bun-build /code/package.json /app/api/package.json

# Copy the lib64 directory for emulation on non-x86_64 platforms
COPY jokes-manager/lib64 /lib64

WORKDIR /app/api

CMD ["bun", "run", "start"]