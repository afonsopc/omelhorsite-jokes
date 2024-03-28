FROM oven/bun:1 as bun-base
FROM afonsopc/holy-c as holy-base

FROM holy-base AS build-holy

# Set the working directory
WORKDIR /code

# Copy the holy code
COPY jokes-manager/Main.HC ./file.HC

# Compile the holy code
RUN hcc ./file.HC
RUN mv a.out /jokes


FROM bun-base AS bun-build

# Set the working directory
WORKDIR /code

# Copy all non ignored files
COPY jokes-api/ .

# Install the dependencies
RUN bun install --frozen-lockfile --production


FROM ubuntu as execute

# Set the environment variables
ENV JOKES_BINARY "/app/bin/jokes"
ENV PORT "3000"
ENV MAX_STRING_LENGTH "255"
ENV JOKES_DB_PATH "/app/database/jokes.db"

# Install the sqlite3 library
RUN apt-get update ; apt-get upgrade -y
RUN apt-get install -y libsqlite3-dev curl unzip

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

# Set the working directory
WORKDIR /app

# Create the database directory
RUN mkdir -p ${JOKES_DB_PATH}
RUN rm -rf ${JOKES_DB_PATH}

# Copy the compiled holy program    
COPY --from=build-holy /jokes /app/bin/jokes

# Copy the built api files
COPY --from=bun-build /code/node_modules /app/api/node_modules
COPY --from=bun-build /code/src/ /app/api/src/
COPY --from=bun-build /code/package.json /app/api/package.json

# Change the working directory
WORKDIR /app/api

CMD ["bun", "run", "start"]