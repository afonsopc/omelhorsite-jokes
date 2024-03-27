#define DB_NAME ("jokes.db")

U0 Panic(U8 *fmt,...) {
  U8 *msg = StrPrintJoin(NULL,fmt,argc,argv);
  "%s\n", msg;
  Free(msg);
  Exit;
}

class Joke {
  U8 *lang;
  U8 *joke;
};

Joke GetRandomJoke(SqlCtx *ctx, U8 *pref_lang, Joke *joke) {
  SqlRow row;
  
  U8 *query = StrPrint(NULL,"SELECT * FROM jokes ORDER BY (CASE WHEN lang = '%s' THEN 0 ELSE 1 END), RANDOM();", pref_lang);

  auto ok = SqlSelect(ctx, &row, query);
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

U0 FormatToJson(U8 *key, U8 *value) {
  U8 *json = StrPrint(NULL,"{\"lang\": \"%s\", \"joke\": \"%s\"}",key,value);
  return json;
}

U8 CreateTableJokes(SqlCtx *ctx) {
  U8 *err = SqlExecRaw(
    ctx,
    "CREATE TABLE IF NOT EXISTS jokes(
       lang TEXT,
       joke TEXT
     );"
  );
  if (err) Panic("Failed to execute query: %s\n",err);
}

U8 AddJoke(SqlCtx *ctx, U8 *lang, U8 *joke) {
  U8 *query = StrPrint(NULL,"INSERT INTO jokes (lang, joke) VALUES ('%s', '%s')", lang, joke);
  
  U8 *err = SqlExecRaw(ctx, query);
  if (err) Panic("Failed to insert items: %s\n", err);
}

U8 GetOperationFromArgs(I32 argc, U8 **argv) {
  if (argc < 2) Panic("Usage:\n %s get <pref_lang>\n %s add <lang> <joke>\n %s getall\n %s delete <lang> <joke>", argv[0], argv[0], argv[0], argv[0]);
  if (StrCmp(argv[1], "get") != 0 && StrCmp(argv[1], "add") != 0 && StrCmp(argv[1], "getall") != 0 && StrCmp(argv[1], "delete") != 0) Panic("Invalid operation: %s\n", argv[1]);
  if (StrCmp(argv[1], "add") == 0 && argc < 4) Panic("Usage:\n %s add <lang> <joke>", argv[0]);
  if (StrCmp(argv[1], "delete") == 0 && argc < 4) Panic("Usage:\n %s delete <lang> <joke>", argv[0]);

  return argv[1];
}

U0 GetAllJokes(SqlCtx *ctx) {
  U0 *query = "SELECT * FROM jokes;";

  SqlRow row;

  I32 *row_count = 0;

  auto ok = SqlSelect(ctx, &row, query);
  if (ok) {
    "{\n";
    " \"jokes\": [\n";
    while (SqlIter(&row)) {
      row_count++;
      if (row_count != 1) ",\n";
      auto joke_lang = row.col[0].str;
      auto joke_text = row.col[1].str;
      U8 *json = FormatToJson(joke_lang, joke_text);
      "   %s", json;
    }
    "\n ]\n";
    "}\n";
  } else {
    "[]\n";
  }
}

U8 DeleteJoke(SqlCtx *ctx, U8 *lang, U8 *joke) {
  U8 *query = StrPrint(NULL,"DELETE FROM jokes WHERE lang = '%s' AND joke = '%s'", lang, joke);
  
  U8 *err = SqlExecRaw(ctx, query);
  if (err) Panic("Failed to delete items: %s\n", err);
}

U0 Main(I32 argc, U8 **argv) {
  U8 *operation = GetOperationFromArgs(argc, argv);

  auto ctx = SqlCtxNew(DB_NAME);
  if (!ctx) Panic("Failed to create database: %s\n", DB_NAME);

  CreateTableJokes(ctx);

  if (StrCmp(operation, "add") == 0) {
    AddJoke(ctx, argv[2], argv[3]);
  } else if (StrCmp(operation, "get") == 0) {
    Joke joke;
    GetRandomJoke(ctx, argv[2], &joke);
    U8 *json = FormatToJson(joke.lang, joke.joke);
    "%s\n", json;
  } else if (StrCmp(operation, "getall") == 0) {
    GetAllJokes(ctx);
  } else if (StrCmp(operation, "delete") == 0) {
    DeleteJoke(ctx, argv[2], argv[3]);
  }

  SqlCtxRelease(ctx);
  Exit();
}
