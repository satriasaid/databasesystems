#!/bin/bash
# Waits for hello.sql, gives the user 5 minutes to type (plus 1 quiet minute),
# then asks headless Claude to solve it and writes hello_answers.sql.
# Runs inside tmux so it survives an SSH disconnect.

DIR=/home/21522611/DBS/PracTest4
W="$DIR/.watcher"
F="$DIR/hello.sql"
OUT="$DIR/hello_answers.sql"
LOG="$W/watcher.log"

log() { echo "[$(date +%T)] $*" >> "$LOG"; }
rm -f "$W/done" "$W/failed"
log "watching for $F"

until [ -e "$F" ]; do sleep 2; done
start=$(stat -c %W "$F" 2>/dev/null)
if [ -z "$start" ] || [ "$start" -le 0 ]; then start=$(date +%s); fi
log "hello.sql created at $(date -d @"$start" +%T), waiting 5 minutes"

while [ $(( $(date +%s) - start )) -lt 300 ]; do sleep 5; done
# wait until the file has not been edited for 60 seconds
while [ $(( $(date +%s) - $(stat -c %Y "$F") )) -lt 60 ]; do sleep 10; done
log "file stable ($(wc -c < "$F") bytes), solving"

# build the context: schema, data, the user's notes (style guide), then the problems
{
  echo "===== pracTest4Tables_2.sql ====="; cat "$DIR/Notes/pracTest4Tables_2.sql"
  echo; echo "===== pracTest4Values_2.sql ====="; cat "$DIR/Notes/pracTest4Values_2.sql"
  echo; echo "===== Explanation.md (the student's notes: concepts and style they know) ====="; cat "$DIR/Notes/Explanation.md"
  echo; echo "===== hello.sql (THE PROBLEMS TO SOLVE) ====="; cat "$F"
} > "$W/input.txt"

PROMPT='You are helping a student with a MySQL 8 practical test. Context on stdin: the table
schema, sample data, the student notes, and hello.sql containing the problems.
Solve every problem in hello.sql. Rules:
- Output ONLY a runnable .sql file. No markdown, no code fences, no prose outside SQL comments.
- Keep each original question as a comment above its answer.
- Use only concepts and the style from the notes: DROP ... IF EXISTS before every CREATE,
  DELIMITER // ... END // ... DELIMITER ; (with a space), DECLAREs at top (variables, cursor, handler),
  READS SQL DATA on functions, IFNULL for NULL maths, SIGNAL SQLSTATE 45000 for errors,
  every UPDATE has a WHERE, and follow every CALL/INSERT/UPDATE/DELETE with a SELECT that shows the result.
- Column and table names must match the schema exactly. Mentally check every statement for syntax
  errors (MySQL 8) and that later questions still work after earlier ones changed the data.
- Where a test call is expected to fail on purpose, add a comment with the expected error.
- If a question is ambiguous, state your assumption in a short comment.'

if claude -p "$PROMPT" < "$W/input.txt" > "$W/raw.sql" 2>> "$LOG"; then
  # strip code fences in case any slipped through
  sed '/^```/d' "$W/raw.sql" > "$OUT"
  log "answers written to $OUT"
  touch "$W/done"
else
  log "claude -p failed (exit $?)"
  touch "$W/failed"
fi
