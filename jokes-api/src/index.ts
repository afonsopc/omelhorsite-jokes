import { Hono } from 'hono'

type Joke = {
  lang: string,
  joke: string
}

type Jokes = { jokes: Joke[] }

const getEnvironmentVariable = (name: string): string => {
  const value = process.env[name]
  if (!value) {
    throw new Error(`${name} is not set`)
  }
  return value
}

const JOKES_BINARY = getEnvironmentVariable('JOKES_BINARY')
const JOKES_DB_PATH = getEnvironmentVariable('JOKES_DB_PATH')
const ACCOUNTS_SERVICE_URL = getEnvironmentVariable('ACCOUNTS_SERVICE_URL')
const _MAX_STRING_LENGTH = getEnvironmentVariable('MAX_STRING_LENGTH')
const MAX_STRING_LENGTH = parseInt(_MAX_STRING_LENGTH)

const cleanString = (str: string): string => {
  if (!str) {
    return ""
  }
  let cleanStr = str.trim()
  if (cleanStr.length > MAX_STRING_LENGTH) {
    cleanStr = cleanStr.substring(0, MAX_STRING_LENGTH)
  }

  return cleanStr
}

function isJoke(obj: any): obj is Joke {
  return obj && typeof obj.lang === 'string' && typeof obj.joke === 'string';
}

function isJokes(obj: any): obj is Jokes {
  return obj && Array.isArray(obj.jokes) && obj.jokes.every(isJoke);
}

const getJoke = async (preferredLang?: string): Promise<Joke> => {
  let response;
  if (preferredLang) {
    response = Bun.spawn([JOKES_BINARY, JOKES_DB_PATH, "get", preferredLang]);
  } else {
    response = Bun.spawn([JOKES_BINARY, JOKES_DB_PATH, "get"]);
  }
  const joke: Joke = await new Response(response.stdout).json()

  if (isJoke(joke)) {
    return joke;
  } else {
    throw new Error("Invalid joke format");
  }
}

const getAllJokes = async (): Promise<Jokes> => {
  const response = Bun.spawn([JOKES_BINARY, JOKES_DB_PATH, "getall"]);
  const joke: Jokes = await new Response(response.stdout).json()

  if (isJokes(joke)) {
    return joke;
  } else {
    throw new Error("Invalid joke format");
  }
}

const addJoke = async (joke: Joke): Promise<void> => {
  const cleanJoke: Joke = {
    lang: cleanString(joke.lang),
    joke: cleanString(joke.joke)
  }

  Bun.spawn([JOKES_BINARY, JOKES_DB_PATH, "add", `${cleanJoke.lang}`, `${cleanJoke.joke}`]);
}

const deleteJoke = async (joke: Joke): Promise<void> => {
  const cleanJoke: Joke = {
    lang: cleanString(joke.lang),
    joke: cleanString(joke.joke)
  }

  Bun.spawn([JOKES_BINARY, JOKES_DB_PATH, "delete", `${cleanJoke.lang}`, `${cleanJoke.joke}`]);
}

const getToken = async (header: string): Promise<string> => {
  return header.substring("Bearer ".length)
}

const isAdmin = async (token: string): Promise<boolean> => {
  const response = await fetch(`${ACCOUNTS_SERVICE_URL}/admin`, {
    method: "GET",
    headers: { "Authorization": `Bearer ${token}` }
  })

  return response.status === 200
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

app.get('/all', async (c) => {
  const header = c.req.header('Authorization')
  if (!header) {
    return c.text('Missing Authorization header', 401)
  }

  const token = await getToken(header)

  if (!await isAdmin(token)) {
    return c.text('Access Denied', 401)
  }

  try {
    const jokes = await getAllJokes()
    return c.json(jokes, 200)
  }
  catch (e) {
    console.error(e)
    return c.text('Failed to get joke', 500)
  }
})

app.post('/', async (c) => {
  let joke;
  try {
    joke = await c.req.json<Joke>()
  }
  catch (e) {
    console.error(e)
    return c.text('Invalid joke format', 400)
  }

  const header = c.req.header('Authorization')
  if (!header) {
    return c.text('Missing Authorization header', 401)
  }

  const token = await getToken(header)

  if (!await isAdmin(token)) {
    return c.text('Access Denied', 401)
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

app.delete('/', async (c) => {
  let joke;
  try {
    joke = await c.req.json<Joke>()
  }
  catch (e) {
    console.error(e)
    return c.text('Invalid joke format', 400)
  }

  const header = c.req.header('Authorization')
  if (!header) {
    return c.text('Missing Authorization header', 401)
  }

  const token = await getToken(header)

  if (!await isAdmin(token)) {
    return c.text('Access Denied', 401)
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

export default {
  fetch: app.fetch
}