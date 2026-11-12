# Project 5 starter: word counts in Redis

A Node.js (Express) app that counts the words of a few books and shows the most frequent ones.
Counting, filtering, routes and pages are done. **You add Redis: the five TODOs in `server.js`.**

| File | |
|---|---|
| `server.js` | the server; TODO 1-5 |
| `public/` | the pages: `index.html`, `word-counts.html`, `unique.html`, `chart.html` |
| `fetch_books.sh` | downloads Pride and Prejudice, War and Peace and Tarzan of the Apes into `books/` |

## Run

```sh
docker exec cse6332-course sh /data/word-count-app/fetch_books.sh            # once
docker exec -it -w /data/word-count-app cse6332-course node server.js        # Ctrl+C stops it
```

Open http://127.0.0.1:9002/word-chart-app/ . After editing `server.js`, stop it with Ctrl+C and start it again.
Any Project Gutenberg `.txt` file in `books/` becomes a book; its file name is the title.

## Redis

Each book is one hash, `book:{title}:word_counts`, with one field per word and the count as the value.
The `redis` package is already installed in the container; its commands are methods on `client`,
for example `client.hSet(key, object)`, `client.hGetAll(key)`, `client.hKeys(key)`, `client.keys(pattern)`
and `client.del(key)`. All of them return promises, so use `await`.

Check your work with `docker exec -it cse6332-course redis-cli`:

    KEYS book:*
    HLEN book:Pride_and_Prejudice:word_counts
    HGET book:Pride_and_Prejudice:word_counts elizabeth
