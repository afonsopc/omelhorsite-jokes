import { Context, Hono } from 'hono'

type Joke = {
  lang: string,
  joke: string
}

type Jokes = { jokes: Joke[] }

const getEnvironmentVariable = (name: string): string => {
  const value = process.env[name]
  if (!value) { throw new Error(`${name} is not set`) }
  return value
}

const JOKES_BINARY = getEnvironmentVariable('JOKES_BINARY')
const JOKES_DB_PATH = getEnvironmentVariable('JOKES_DB_PATH')
const ACCOUNTS_SERVICE_URL = getEnvironmentVariable('ACCOUNTS_SERVICE_URL')
const _MAX_STRING_LENGTH = getEnvironmentVariable('MAX_STRING_LENGTH')
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
  return obj && typeof obj.lang === 'string' && typeof obj.joke === 'string';
}

function isJokes(obj: any): obj is Jokes {
  return obj && Array.isArray(obj.jokes) && obj.jokes.every(isJoke);
}

const runJokesBinary = async (_args: (string | undefined)[]): Promise<ReadableStream<Uint8Array>> => {
  const args = _args.filter((arg) => arg !== undefined) as string[];
  const response = Bun.spawn([JOKES_BINARY, JOKES_DB_PATH, ...args]);
  return response.stdout;
}

const getJoke = async (preferredLang?: string): Promise<Joke> => {
  const response = runJokesBinary(["get", preferredLang]);
  const joke: Joke = await new Response(await response).json()

  if (isJoke(joke)) {
    return joke;
  } else {
    throw new Error("Invalid joke format");
  }
}

const getAllJokes = async (): Promise<Jokes> => {
  const response = runJokesBinary(["getall"]);
  const joke: Jokes = await new Response(await response).json()

  if (isJokes(joke)) {
    return joke;
  } else {
    throw new Error("Invalid joke format");
  }
}

const addJoke = async (_joke: Joke): Promise<void> => {
  const joke: Joke = cleanJoke(_joke);

  runJokesBinary(["add", `${joke.lang}`, `${joke.joke}`]);
}

const deleteJoke = async (_joke: Joke): Promise<void> => {
  const joke: Joke = cleanJoke(_joke);

  runJokesBinary(["delete", `${joke.lang}`, `${joke.joke}`]);
}

// Middleware for checking if user is an admin
const checkAdmin = async (c: Context, next: () => Promise<void>) => {
  const header = c.req.header('Authorization')
  if (!header) { return c.text('Missing Authorization header', 401) }

  const token = header.substring("Bearer ".length);
  const response = await fetch(`${ACCOUNTS_SERVICE_URL}/admin`, {
    method: "GET",
    headers: { "Authorization": `Bearer ${token}` }
  })

  if (response.status !== 200) { return c.text('Access Denied', 401) }
  await next()
}

const app = new Hono()

app.get('/', async (c) => {
  const preferredLang = c.req.query('preferredLang')
  try {
    const joke = await getJoke(preferredLang)
    return c.json(joke, 200)
  }
  catch (e) {
    console.error(e)
    return c.text('Failed to get joke', 500)
  }
})

app.get('/all', checkAdmin, async (c) => {
  try {
    const jokes = await getAllJokes()
    return c.json(jokes, 200)
  }
  catch (e) {
    console.error(e)
    return c.text('Failed to get joke', 500)
  }
})

app.post('/', checkAdmin, async (c) => {
  let joke;
  try { joke = await c.req.json<Joke>() }
  catch (e) {
    console.error(e)
    return c.text('Invalid joke format', 400)
  }

  try {
    addJoke(joke)
    return c.text('Joke added successfully', 201)
  }
  catch (e) {
    console.error(e)
    return c.text('Failed to add joke', 500)
  }
})

app.delete('/', checkAdmin, async (c) => {
  let joke;
  try { joke = await c.req.json<Joke>() }
  catch (e) {
    console.error(e)
    return c.text('Invalid joke format', 400)
  }

  try {
    deleteJoke(joke)
    return c.text('Joke deleted successfully', 200)
  }
  catch (e) {
    console.error(e)
    return c.text('Failed to delete joke', 500)
  }
})

export default app