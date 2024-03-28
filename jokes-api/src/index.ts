import { Hono } from 'hono'


type Joke = {
  lang: string,
  joke: string
}

function isJoke(obj: any): obj is Joke {
  return obj && typeof obj.lang === 'string' && typeof obj.joke === 'string';
}

const JOKES_BINARY = process.env.JOKES_BINARY
if (!JOKES_BINARY) {
  throw new Error('JOKES_BINARY is not set')
}

const PORT = process.env.PORT
if (!PORT) {
  throw new Error('PORT is not set')
}

const _MAX_STRING_LENGTH = process.env.MAX_STRING_LENGTH
if (!_MAX_STRING_LENGTH) {
  throw new Error('MAX_STRING_LENGTH is not set')
}
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

const app = new Hono()

const getJoke = async (): Promise<Joke> => {
  const response = Bun.spawn([JOKES_BINARY, "get"]);
  const joke = await new Response(response.stdout).text()
  console.log(joke);

  const jokeObj: Joke = JSON.parse(joke)


  if (isJoke(jokeObj)) {
    return jokeObj;
  } else {
    throw new Error("Invalid joke format");
  }
}

const addJoke = async (joke: Joke): Promise<void> => {
  const cleanJoke: Joke = {
    lang: cleanString(joke.lang),
    joke: cleanString(joke.joke)
  }

  const response = Bun.spawn([JOKES_BINARY, "add", `${cleanJoke.lang}`, `${cleanJoke.joke}`]);
  if (response.exitCode !== 0) {
    throw new Error("Failed to add joke");
  }
}

app.get('/', async (c) => {
  try {
    const joke = await getJoke()
    return c.json(joke, 200)
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
  try {
    addJoke(joke)
    return c.text('Joke added successfully', 201)
  }
  catch (e) {
    console.error(e)
    return c.text('Failed to add joke', 500)
  }
})

export default {
  port: PORT,
  fetch: app.fetch
}