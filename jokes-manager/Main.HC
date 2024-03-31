#define SQL_TEXT 3

U0 Panic(U8 *fmt,...) {
  U8 *error = "ERROR: %s";
  U8 *msg = StrPrintJoin(NULL, error, fmt);
  msg = StrPrintJoin(NULL,msg,argc,argv);
  "%s\n", msg;
  Free(msg);
  Exit(1);
}

U0 PrintAboutSection(I32 argc, U8 **argv) {
  "\nJokes Manager\n";
  " Version 1.0\n";
  " Author: Afonso Coutinho\n";
  " Date: 28/03/2024\n";
  " Location: Portugal\n";
  " Description: A simple database manager for storing jokes in multiple languages. Written in the Holy C language using the compiler from https://github.com/Jamesbarford/holyc-lang.\n\n";
  " Usage:\n";
  "   %s <db_path> get [pref_lang]\n", argv[0];
  "   %s <db_path> add <lang> <joke>\n", argv[0];
  "   %s <db_path> getall\n", argv[0];
  "   %s <db_path> delete <lang> <joke>\n", argv[0];
  "   %s <db_path> deleteall\n", argv[0];
  "   %s <db_path> createdb\n", argv[0];
  "   %s <db_path> healthcheck\n", argv[0];
  "   %s <db_path> help\n", argv[0];
  "   %s <db_path> about\n", argv[0];
  "\n";
}

U0 PrintHelpSection(I32 argc, U8 **argv) {
  "\nJokes Manager\n";
  " Version 1.0\n\n";
  " Usage:\n";
  "   %s <db_path> get [pref_lang]\n", argv[0];
  "   %s <db_path> add <lang> <joke>\n", argv[0];
  "   %s <db_path> getall\n", argv[0];
  "   %s <db_path> delete <lang> <joke>\n", argv[0];
  "   %s <db_path> deleteall\n", argv[0];
  "   %s <db_path> createdb\n", argv[0];
  "   %s <db_path> healthcheck\n", argv[0];
  "   %s <db_path> help\n", argv[0];
  "   %s <db_path> about\n", argv[0];
  "\n";
}

U8 *GetOperationFromArgs(I32 argc, U8 **argv) {
  if (argc < 3) {
    PrintHelpSection();
    Panic("\nInvalid number of arguments.");
  } else if (
    StrCmp(argv[2], "get") != 0 && 
    StrCmp(argv[2], "add") != 0 && 
    StrCmp(argv[2], "getall") != 0 && 
    StrCmp(argv[2], "delete") != 0 && 
    StrCmp(argv[2], "about") != 0 && 
    StrCmp(argv[2], "help") != 0 &&
    StrCmp(argv[2], "deleteall") != 0 &&
    StrCmp(argv[2], "createdb") != 0 &&
    StrCmp(argv[2], "healthcheck") != 0
  ) {
    Panic("Invalid operation: %s", argv[2]);
  } else if (StrCmp(argv[2], "add") == 0 && argc < 4) {
    Panic("Usage:\n %s <db_path> add <lang> <joke>", argv[0]);
  } else if (StrCmp(argv[2], "delete") == 0 && argc < 4) {
    Panic("Usage:\n %s <db_path> delete <lang> <joke>", argv[0]);
  }

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
  if (err) Panic("Failed to create the jokes table: %s",err);
}

U0 AddJoke(SqlCtx *ctx, U8 *lang, U8 *joke) {
  U8 *query = "INSERT INTO jokes (lang, joke) VALUES (?, ?)";
  
  SqlParam params[2];

  params[0].type = SQL_TEXT;
  params[0].str = lang;

  params[1].type = SQL_TEXT;
  params[1].str = joke;

  Bool success = SqlQuery(ctx, query, params, 2);
  if (!success) Panic("Failed to add joke to database");

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

U0 DeleteJoke(SqlCtx *ctx, U8 *lang, U8 *joke) {
  U8 *query = "DELETE FROM jokes WHERE lang = ? AND joke = ?";
  
  SqlParam params[2];

  params[0].type = SQL_TEXT;
  params[0].str = lang;

  params[1].type = SQL_TEXT;
  params[1].str = joke;

  Bool success = SqlQuery(ctx, query, params, 2);
  if (!success) Panic("Failed to delete joke from database.");

  "Joke deleted successfully.\n";
}

U0 DeleteAllJokes(SqlCtx *ctx) {
  U8 *query = "DELETE FROM jokes;";

  Bool success = SqlQuery(ctx, query);
  if (!success) Panic("Failed to delete all jokes from database.");

  "All jokes deleted successfully.\n";
}

U0 PrintHealthCheckSection() {
  "Health check passed.\n\n";
  "Fernando Farinha - Destino Marcado:\n"
  " O fado tem não sei quê\n"
  " Que prende a vida da gente\n"
  " Um nada que se não vê\n"
  " Um tudo que a gente sente\n\n"
  "Joke Manager is healthy.\n";
}

U0 PrintCreatedDbSection() {
  "Database created successfully.\n";
}

U0 Main(I32 argc, U8 **argv) {
  U8 *operation = GetOperationFromArgs(argc, argv);
  U8 *db_path = GetDatabasePathFromArgs(argc, argv);

  auto ctx = SqlCtxNew(db_path);
  if (!ctx) Panic("Failed to create database: %s", db_path);

  CreateTableJokes(ctx);

  if (StrCmp(operation, "add") == 0) {
    AddJoke(ctx, argv[3], argv[4]);
  } else if (StrCmp(operation, "get") == 0) {
    PrintRandomJoke(ctx, argv[3]);
  } else if (StrCmp(operation, "getall") == 0) {
    PrintAllJokes(ctx);
  } else if (StrCmp(operation, "delete") == 0) {
    DeleteJoke(ctx, argv[3], argv[4]);
  } else if (StrCmp(operation, "about") == 0) {
    PrintAboutSection(argc, argv);
  } else if (StrCmp(operation, "help") == 0) {
    PrintHelpSection(argc, argv);
  } else if (StrCmp(operation, "deleteall") == 0) {
    DeleteAllJokes(ctx);
  } else if (StrCmp(operation, "createdb") == 0) {
    PrintCreatedDbSection();
  } else if (StrCmp(operation, "healthcheck") == 0) {
    PrintHealthCheckSection();
  } else {
    PrintHelpSection(argc, argv);
    Panic("Invalid operation: %s", operation);
  }

  SqlCtxRelease(ctx);
  Exit(0);
}
