#define DB_NAME ("text.db")

U0 Panic(U8 *fmt,...) {
  U8 *msg = StrPrintJoin(NULL,fmt,argc,argv);
  "%s\n",
  Free(msg);
  Exit;
}

class Joke {
  U8 *lang;
  U8 *joke;
};

Joke GetRandomRow(SqlCtx *ctx, U8 *pref_lang, Joke *joke) {
  SqlRow row;
  
  auto ok = SqlSelect(ctx,&row,"SELECT * FROM jokes ORDER BY RANDOM() LIMIT 1;", pref_lang);
  if (ok) {
    while (SqlIter(&row)) {
      auto rand_joke_lang = row.col[0].str;
      auto rand_joke = row.col[1].str;
      joke->lang = rand_joke_lang;
      joke->joke = rand_joke;
      return joke;
    }
  }

  joke->lang = "en";
  joke->joke = "No jokes available.";
  return joke;
}

U0 Main() {
  U8 *err;
  auto ctx = SqlCtxNew(DB_NAME);
  if (!ctx) Panic("Failed to create database: %s\n", DB_NAME);

  err = SqlExecRaw(ctx,
    "CREATE TABLE IF NOT EXISTS jokes(
       lang TEXT,
       joke TEXT
     );");
  if (err) Panic("Failed to execute query: %s\n",err);

  err = SqlExecRaw(ctx,
      "INSERT INTO jokes(lang,joke) VALUES 
        ('en','Why did the chicken cross the road?'),
        ('en','Who'),
        ('pt','Quem tem medo?');
  ");
  if (err) Panic("Failed to insert items: %s\n", err);

  Joke joke;
  GetRandomRow(ctx, "pt", &joke);
  "%s: %s\n", joke.lang, joke.joke;

  SqlCtxRelease(ctx);
}
