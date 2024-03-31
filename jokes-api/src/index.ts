import { Context, Hono } from "hono"
import { cors } from "hono/cors"

type Joke = {
  lang: string,
  joke: string
}

type Jokes = { jokes: Joke[] }

type JokeManagerResponse = {
  success: boolean,
  output: string
}

const getEnvironmentVariable = (name: string): string => {
  const value = process.env[name]
  if (!value) { throw new Error(`${name} is not set`) }
  return value
}

const ERROR_MESSAGE = "ERROR";

const _JOKES_BINARY = getEnvironmentVariable("JOKES_BINARY")

// if arch is not amd64 add qemu-amd64 to the command
const JOMES_MANAGER = [_JOKES_BINARY]
if (process.arch !== "x64") {
  JOMES_MANAGER.unshift("qemu-amd64")
}

const JOKES_DB_PATH = getEnvironmentVariable("JOKES_DB_PATH")
const ACCOUNTS_SERVICE_URL = getEnvironmentVariable("ACCOUNTS_SERVICE_URL")
const _MAX_STRING_LENGTH = getEnvironmentVariable("MAX_STRING_LENGTH")
const MAX_STRING_LENGTH = parseInt(_MAX_STRING_LENGTH)

const cleanString = (str: string): string => {
  if (!str) { return "" }
  let cleanStr = str.trim()
  if (cleanStr.length > MAX_STRING_LENGTH) {
    cleanStr = cleanStr.substring(0, MAX_STRING_LENGTH)
  }

  return cleanStr
}

const cleanJoke = (joke: Joke): Joke => {
  return {
    lang: cleanString(joke.lang),
    joke: cleanString(joke.joke)
  }
}

function isJoke(obj: any): obj is Joke {
  return obj && typeof obj.lang === "string" && typeof obj.joke === "string";
}

function isJokes(obj: any): obj is Jokes {
  return obj && Array.isArray(obj.jokes) && obj.jokes.every(isJoke);
}

const runJokesManager = async (_args: (string | undefined)[]): Promise<JokeManagerResponse> => {
  const args = _args.filter((arg) => arg !== undefined) as string[];
  const command_args = [...JOMES_MANAGER, JOKES_DB_PATH, ...args]
  const response = Bun.spawn(command_args);
  const output = await new Response(response.stdout).text()
  const success = !output.startsWith(ERROR_MESSAGE)

  console.log(`Executed command: "${command_args.join(" ")}"; Success: "${success}"; Output: "${output}";`)

  return { success, output };
}

const getJoke = async (preferredLang?: string): Promise<Joke> => {
  const response = await runJokesManager(["get", preferredLang]);

  let joke: Joke;
  try { joke = JSON.parse(response.output) }
  catch (e) { throw new Error("Failed to parse joke") }

  if (response.success && isJoke(joke)) { return joke }
  else { throw new Error("Recieved an invalid joke format") }
}

const getAllJokes = async (): Promise<Jokes> => {
  const response = await runJokesManager(["getall"]);

  let joke: Joke;
  try { joke = JSON.parse(response.output) }
  catch (e) { throw new Error("Failed to parse joke") }

  if (response.success && isJokes(joke)) { return joke }
  else { throw new Error("Recieved an invalid joke format") }
}

const addJoke = async (joke: Joke): Promise<void> => {
  const cleanedJoke: Joke = cleanJoke(joke);
  const response = await runJokesManager(["add", `${cleanedJoke.lang}`, `${cleanedJoke.joke}`]);

  if (response.success) { return }
  else { throw new Error("Failed to add joke") }
}

const deleteJoke = async (joke: Joke): Promise<void> => {
  const cleanedJoke: Joke = cleanJoke(joke);
  const response = await runJokesManager(["delete", `${cleanedJoke.lang}`, `${cleanedJoke.joke}`]);

  if (response.success) { return }
  else { throw new Error("Failed to delete joke") }
}

// Middleware for checking if user is an admin
const checkAdmin = async (c: Context, next: () => Promise<void>) => {
  const header = c.req.header("Authorization")
  if (!header) { return c.text("Missing Authorization header", 401) }

  const token = header.substring("Bearer ".length);
  const response = await fetch(`${ACCOUNTS_SERVICE_URL}/admin`, {
    method: "GET",
    headers: { "Authorization": `Bearer ${token}` }
  })

  if (response.status !== 200) { return c.text("Access Denied", 401) }
  await next()
}

const app = new Hono()

app.use("/*", cors())

app.get("/", async (c) => { return c.text("Dizem que o fado desgraça\nO fado de muita gente\nMentira, o fado não passa\nDum fado que qualquer sente", 200) })

app.get("/joke", async (c) => {
  const preferredLang = c.req.query("preferredLang")
  try {
    const joke = await getJoke(preferredLang)
    return c.json(joke, 200)
  }
  catch (e) {
    console.error(e)
    return c.text("Failed to get joke", 500)
  }
})

app.get("/jokes", checkAdmin, async (c) => {
  try {
    const jokes = await getAllJokes()
    return c.json(jokes, 200)
  }
  catch (e) {
    console.error(e)
    return c.text("Failed to get joke", 500)
  }
})

app.post("/joke", checkAdmin, async (c) => {
  let joke;
  try { joke = await c.req.json<Joke>() }
  catch (e) {
    console.error(e)
    return c.text("Invalid joke format", 400)
  }

  try {
    addJoke(joke);
    return c.text("Joke added successfully", 201)
  }
  catch (e) {
    console.error(e)
    return c.text("Failed to add joke", 500)
  }
})

app.delete("/joke", checkAdmin, async (c) => {
  let joke;
  try { joke = await c.req.json<Joke>() }
  catch (e) {
    console.error(e)
    return c.text("Invalid joke format", 400)
  }

  try {
    deleteJoke(joke);
    return c.text("Joke deleted successfully", 200)
  }
  catch (e) {
    console.error(e)
    return c.text("Failed to delete joke", 500)
  }
})

export default app