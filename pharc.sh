#!/bin/bash
#####
# USAGE
# 1. `pharc reviews` - get the diffs you're in as a reviewer
# 2. `pharc assigned` - get the tasks you have assigned
# 3. `pharc diffs [-u username] [-c --closed]` - get your or someone else's diffs
# 4. `pharc task [-c --create] [--no-branch]` - create a task and a optionally local branch
#####
# DATABASE
#  - Users
#    id | phid | self | username
#  - Secrets
#    id | secret
####
URI="https://phabricator.tools.fln-ltd.net"

function get_reviews() {
  echo "$@"
}

function get_tasks() {
  echo "$@"
}

function get_diffs() {
  token=$(get_secret)
  uphid=$(get_self_db phid)
  json="{"constraints": {"authors": ["$uphid"], "status": ["open"]}, "order": "newest"}"
  return $(echo "$json" | arc call-conduit --conduit-uri "$URI" --conduit-token "$token" differential.revision.search)
}

function create_task() {
  echo "$@"
}

while [[ "$#" -gt 0 ]]; do
  key="$1"
  case $key in
    reviews)
      shift; get_reviews "$@"
      break
      ;;
    assigned)
      shift; get_tasks "$@"
      break
      ;;
    diffs)
      shift; get_diffs "$@"
      break
      ;;
    task)
      shift; create_task "$@"
      break
      ;;
    *)
      shift
      ;;
  esac
done

#######
# API #
#######

function setup() {
  setup_db
  echo "Provide your API token which you can generate at: "
  read secret
  save_secret "$secret"
  user=$(get_self_arc)
  echo "$user"
}

###############
# ARC METHODS #
###############

function get_user_arc() {
  token=get_token
  json="{"constraints": {"username": ["$1"]}}"
  return $(echo "$json" | arc call-conduit --conduit-uri "$URI" --conduit-token "$token" user.search)
}

function get_self_arc() {
  token=get_token
  return $(arc call-conduit --conduit-uri "$URI" --conduit-token "$token" user.whoami)
}

##############
# DB METHODS #
##############

DBNAME="pharc"

function save_user() {
  sqlite3 "$DBNAME" "INSERT INTO users (phid, username, self) VALUES ($1, $2, $3);"
}

function get_self_db() {
  return get_user_db $1 self 1
}

function get_user_db() {
    query="SELECT $1 FROM users WHERE $2=$3;"
    return $(sqlite3 "$DBNAME" "$query")
}

function save_secret() {
  return $(sqlite3 "$DBNAME" "INSERT INTO secrets (secret) VALUES ($1);")
}

function get_secret() {
  return $(sqlite3 "$DBNAME" "SELECT secret FROM secrets ORDER BY id DESC LIMIT 1;")
}

function setup_db() {
  sqlite3 "$DBNAME" "
    CREATE TABLE IF NOT EXISTS
      secret(
        id integer PRIMARY KEY,
        secret TEXT NOT NULL UNIQUE
      );"
  sqlite3 "$DBNAME" "
    CREATE TABLE IF NOT EXISTS
      users(
        id INTEGER PRIMARY KEY,
        phid TEXT NOT NULL UNIQUE,
        self INTEGER UNIQUE,
        username TEXT NOT NULL UNIQUE
      );"
}


