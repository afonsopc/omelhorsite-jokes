FROM afonsopc/holy-c as build-holy

# Set the working directory
WORKDIR /code

# Copy the holy code
COPY jokes-database/Main.HC ./file.HC

# Compile the holy code
RUN hcc ./file.HC
RUN mv a.out /jokes

FROM ubuntu as execute

# Install the sqlite3 library
RUN apt-get update ; apt-get upgrade -y
RUN apt-get install -y libsqlite3-dev

# Copy the compiled holy program
COPY --from=build-holy /jokes /

CMD ["/jokes"]