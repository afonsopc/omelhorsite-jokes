FROM afonsopc/holy-c as build-holy

# Set the working directory
WORKDIR /code

# Copy the holy code
COPY file.HC ./file.HC

# Compile the holy code
RUN hcc ./file.HC
RUN mv a.out /add-joke

FROM ubuntu as execute

# Install the sqlite3 library
RUN apt-get update ; apt-get upgrade -y
RUN apt-get install -y libsqlite3-dev

# Copy the compiled holy program
COPY --from=build-holy /add-joke /

CMD ["/add-joke"]