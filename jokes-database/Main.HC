#define SQL_TEXT 3

U0 Panic(U8 *fmt,...) {
  U8 *msg = StrPrintJoin(NULL,fmt,argc,argv);
  "%s\n", msg;
  Free(msg);
  Exit;
}

U8 *GetOperationFromArgs(I32 argc, U8 **argv) {
  if (argc < 3) Panic("Usage:\n %s <db_path> get [pref_lang]\n %s <db_path> add <lang> <joke>\n %s <db_path> getall\n %s <db_path> delete <lang> <joke>", argv[0], argv[0], argv[0], argv[0]);
  if (StrCmp(argv[2], "get") != 0 && StrCmp(argv[2], "add") != 0 && StrCmp(argv[2], "getall") != 0 && StrCmp(argv[2], "delete") != 0) Panic("Invalid operation: %s\n", argv[2]);
  if (StrCmp(argv[2], "add") == 0 && argc < 4) Panic("Usage:\n %s <db_path> add <lang> <joke>", argv[0]);
  if (StrCmp(argv[2], "delete") == 0 && argc < 4) Panic("Usage:\n %s <db_path> delete <lang> <joke>", argv[0]);

  return argv[2];
}

U8 *GetDatabasePathFromArgs(I32 argc, U8 **argv) {
  return argv[1];
}

U8 *FormatJokeToJson(U8 *lang, U8 *joke) {
  U8 *json = StrPrint(NULL,"{\"lang\": \"%s\", \"joke\": \"%s\"}",lang,joke);
  return json;
}

U0 CreateTableJokes(SqlCtx *ctx) {
  U8 *err = SqlExecRaw(
    ctx,
    "CREATE TABLE IF NOT EXISTS jokes(
       lang TEXT,
       joke TEXT
     );"
  );
  if (err) Panic("Failed to create the jokes table: %s\n",err);
}

U0 AddJoke(SqlCtx *ctx, U8 *lang, U8 *joke) {
  U8 *query = "INSERT INTO jokes (lang, joke) VALUES (?, ?)";
  
  SqlParam params[2];

  params[0].type = SQL_TEXT;
  params[0].str = lang;

  params[1].type = SQL_TEXT;
  params[1].str = joke;

  Bool success = SqlQuery(ctx, query, params, 2);
  if (!success) Panic("Failed to add joke to database\n");

  "Joke added successfully.\n";
}

U0 PrintRandomJoke(SqlCtx *ctx, U8 *pref_lang) {
  SqlRow row;
  
  U8 *query = "SELECT * FROM jokes ORDER BY (CASE WHEN lang = ? THEN 0 ELSE 1 END), RANDOM();";

  SqlParam params[1];

  params[0].type = SQL_TEXT;
  params[0].str = pref_lang;

  Bool success = SqlSelect(ctx, &row, query, params, 1);
  if (success) {
    while (SqlIter(&row)) {
      auto rand_joke_lang = row.col[0].str;
      auto rand_joke = row.col[1].str;
      U8 *json = FormatJokeToJson(rand_joke_lang, rand_joke);
      "%s\n", json;
      return;
    }
  }

  U8 *json = FormatJokeToJson("en", "No jokes available.");
  "%s\n", json;
}

U0 PrintAllJokes(SqlCtx *ctx) {
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
      U8 *json = FormatJokeToJson(joke_lang, joke_text);
      "   %s", json;
    }
    if (row_count == 0) {
      U8 *json = FormatJokeToJson("en", "No jokes available.");
      "   %s", json;
    }
    "\n ]\n";
    "}\n";
  } else {
    "[]\n";
  }
}

U8 DeleteJoke(SqlCtx *ctx, U8 *lang, U8 *joke) {
  U8 *query = "DELETE FROM jokes WHERE lang = ? AND joke = ?";
  
  SqlParam params[2];

  params[0].type = SQL_TEXT;
  params[0].str = lang;

  params[1].type = SQL_TEXT;
  params[1].str = joke;

  Bool success = SqlQuery(ctx, query, params, 2);
  if (!success) Panic("Failed to delete joke from database.\n");

  "Joke deleted successfully.\n";
}

U0 Main(I32 argc, U8 **argv) {
  U8 *operation = GetOperationFromArgs(argc, argv);
  U8 *db_path = GetDatabasePathFromArgs(argc, argv);

  auto ctx = SqlCtxNew(db_path);
  if (!ctx) Panic("Failed to create database: %s\n", db_path);

  CreateTableJokes(ctx);

  if (StrCmp(operation, "add") == 0) {
    AddJoke(ctx, argv[3], argv[4]);
  } else if (StrCmp(operation, "get") == 0) {
    PrintRandomJoke(ctx, argv[3]);
  } else if (StrCmp(operation, "getall") == 0) {
    PrintAllJokes(ctx);
  } else if (StrCmp(operation, "delete") == 0) {
    DeleteJoke(ctx, argv[3], argv[4]);
  }

  SqlCtxRelease(ctx);
  Exit();
}
