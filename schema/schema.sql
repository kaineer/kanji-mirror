-- kanji-mirror schema (SQLite)
-- See docs/schema.md for entity descriptions.

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------------
-- chapter: список уроков (например N5, N4)
-- ---------------------------------------------------------------------------
CREATE TABLE chapter (
    id    INTEGER PRIMARY KEY,
    title TEXT    NOT NULL
);

-- ---------------------------------------------------------------------------
-- lesson: урок; порядок внутри главы — связный список через prev_id
-- (удобная вставка в середину без перенумерации position)
-- ---------------------------------------------------------------------------
CREATE TABLE lesson (
    id         INTEGER PRIMARY KEY,
    prev_id    INTEGER REFERENCES lesson (id) ON DELETE SET NULL,
    title      TEXT,
    chapter_id INTEGER NOT NULL REFERENCES chapter (id) ON DELETE CASCADE
);

CREATE INDEX idx_lesson_chapter_id ON lesson (chapter_id);
CREATE INDEX idx_lesson_prev_id ON lesson (prev_id);

-- ---------------------------------------------------------------------------
-- kanji: символ и чтения (несколько чтений — через ・)
-- ---------------------------------------------------------------------------
CREATE TABLE kanji (
    char         TEXT PRIMARY KEY CHECK (length(char) >= 1),
    on_yomi      TEXT,
    kun_yomi     TEXT,
    nanori_yomi  TEXT
);

-- ---------------------------------------------------------------------------
-- lesson_phrase: фраза в уроке, поясняющая символ
-- ---------------------------------------------------------------------------
CREATE TABLE lesson_phrase (
    phrase_id      INTEGER PRIMARY KEY,
    lesson_id      INTEGER NOT NULL REFERENCES lesson (id) ON DELETE CASCADE,
    kanji          TEXT    NOT NULL REFERENCES kanji (char) ON DELETE RESTRICT,
    is_nanori      INTEGER NOT NULL DEFAULT 0 CHECK (is_nanori IN (0, 1)),
    phrase         TEXT    NOT NULL,
    phrase_reading TEXT    NOT NULL
);

CREATE INDEX idx_lesson_phrase_lesson_id ON lesson_phrase (lesson_id);
CREATE INDEX idx_lesson_phrase_kanji ON lesson_phrase (kanji);

-- ---------------------------------------------------------------------------
-- phrase_kanji: все кандзи во фразе (+ main / first)
-- ---------------------------------------------------------------------------
CREATE TABLE phrase_kanji (
    phrase_id INTEGER NOT NULL REFERENCES lesson_phrase (phrase_id) ON DELETE CASCADE,
    kanji     TEXT    NOT NULL REFERENCES kanji (char) ON DELETE RESTRICT,
    main      INTEGER NOT NULL DEFAULT 0 CHECK (main IN (0, 1)),
    first     INTEGER NOT NULL DEFAULT 0 CHECK (first IN (0, 1)),
    PRIMARY KEY (phrase_id, kanji)
);

CREATE INDEX idx_phrase_kanji_kanji ON phrase_kanji (kanji);

-- Не больше одного main-символа на фразу
CREATE UNIQUE INDEX uq_phrase_kanji_main
    ON phrase_kanji (phrase_id)
    WHERE main = 1;
