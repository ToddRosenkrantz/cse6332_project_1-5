// server.js - Project 5 starter: word counts for books, stored in Redis.
//
// Everything except Redis is already written: reading the books, counting words, the stop-word
// filters, the routes and the web pages in public/. Your job is the five TODOs, which store the
// word counts in Redis and read them back:
//   TODO 1  store each book's word counts in Redis          (indexBooks)
//   TODO 2  list the books that are in Redis                (GET /word-chart-app/api/books)
//   TODO 3  read one book's word counts for the top-N list  (GET /word-chart-app/api/book/:title/top/:n)
//   TODO 4  read the words of two books to compare them     (GET /word-chart-app/api/compare-words)
//   TODO 5  read one book's word counts for the chart page  (GET /word-chart-app/api/chart-data/:title/:n)
//
// Run it inside the container (books go in /data/word-count-app/books, see README.md):
//   docker exec -it -w /data/word-count-app cse6332-course node server.js
// then open http://127.0.0.1:9002/word-chart-app/
//
// Until the TODOs are done the server runs, but the pages show no books.

const express = require('express');
const fs = require('fs');
const path = require('path');
const redis = require('redis');
const readline = require('readline');

const app = express();
const PORT = 9002;                               // one of the container's open ports (9000-9009)
const BOOKS_DIR = path.join(__dirname, 'books');

const BASIC_STOP_WORDS = new Set([
  "a","an","the","and","of","to","in","is",
  "it","that","for","on","with","as","was",
  "at","by","be","this","which",
  "he","him","his",
  "she","her","hers",
  "they","them","their",
  "we","our",
  "i","me","my",
  "you","your",
  "are","were","have","has","had",
  "do","does","did"
]);

const LITERARY_STOP_WORDS = new Set([
  ...BASIC_STOP_WORDS,
  "said",
  "mr",
  "mrs",
  "miss",
  "sir",
  "lady",
  "would",
  "could",
  "upon",
  "shall",
  "must"
]);

// Redis runs in the same container. 127.0.0.1, not localhost: looking up "localhost" is slow here.
const client = redis.createClient({ url: 'redis://127.0.0.1:6379' });
client.connect().catch(console.error);

app.use('/word-chart-app', express.static(path.join(__dirname, 'public')));

// Utility to count words from a stream
async function countWordsFromFile(filePath) {
  const wordCounts = {};
  const rl = readline.createInterface({
    input: fs.createReadStream(filePath),
    crlfDelay: Infinity
  });

  for await (const line of rl) {
    const words = line.toLowerCase().match(/\b[a-z']+\b/g);
    if (words) {
      for (const word of words) {
        if (
          word.startsWith("'") ||                  // Skip words that start with '
          word.length <= 1 ||                       // Skip too-short words
          /^[']+$/.test(word)                       // Skip words that are only apostrophes
        ) {
          continue;
        }
        wordCounts[word] = (wordCounts[word] || 0) + 1;
      }
    }
  }

  return wordCounts;
}

// Scan books directory and update Redis
async function indexBooks() {
  const files = fs.readdirSync(BOOKS_DIR).filter(f => f.endsWith('.txt'));

  for (const file of files) {
    const title = path.basename(file, '.txt');
    const fullPath = path.join(BOOKS_DIR, file);
    const wordCounts = await countWordsFromFile(fullPath);   // { word: count, ... }
    const redisKey = `book:${title}:word_counts`;

    // TODO 1: store this book's word counts in Redis as a hash: one field per word, the count as its value.
    //   - First delete redisKey, so counts from an earlier start are not left behind.
    //   - Then write the whole wordCounts object to the hash in one command.

    console.log(`Indexed book: ${title}`);
  }
}

function filterWords(words, filterType = 'basic') {

  if (filterType === 'none') {
    return words;
  }

  const filterSet =
    filterType === 'literary'
      ? LITERARY_STOP_WORDS
      : BASIC_STOP_WORDS;

  return words.filter(item => {
    const word =
      typeof item === 'string'
        ? item
        : item.word;

    return !filterSet.has(word.toLowerCase());
  });
}

// API route to list books
app.get('/word-chart-app/api/books', async (req, res) => {
  // TODO 2: get the names of all keys that match book:*:word_counts .
  const keys = [];
  const titles = keys.map(k => k.split(':')[1]);
  res.json([...new Set(titles)]);
});

// API route to get top N words for a book

app.get('/word-chart-app/api/book/:title/top/:n', async (req, res) => {
  const { title, n } = req.params;
  const { filter = 'basic' } = req.query;

  const redisKey = `book:${title}:word_counts`;
  // TODO 3: read every field and value of the hash redisKey (an object { word: "count", ... }).
  const wordMap = {};

  let entries = Object.entries(wordMap)
    .map(([word, count]) => ({
      word,
      count: parseInt(count)
    }));

  entries = filterWords(entries, filter);
  entries.sort((a, b) => b.count - a.count);
  res.json(entries.slice(0, parseInt(n)));
});

app.get('/word-chart-app/api/compare-words', async (req, res) => {
  const { book1, book2, filter = 'basic' } = req.query;

  if (!book1 || !book2) {
    return res.status(400).json({
      error: 'Both book1 and book2 must be specified'
    });
  }

  try {
    const redisKey1 = `book:${book1}:word_counts`;
    const redisKey2 = `book:${book2}:word_counts`;

    // TODO 4: read only the field names (the words) of both hashes, at the same time.
    const [words1, words2] = await Promise.all([
      [],
      []
    ]);

    if (words1.length === 0 || words2.length === 0) {
      return res.status(404).json({
        error: 'One or both books not found in database'
      });
    }

    const filtered1 = filterWords(words1, filter);
    const filtered2 = filterWords(words2, filter);

    const set1 = new Set(filtered1);
    const set2 = new Set(filtered2);

    const uniqueToBook1 = [...set1]
      .filter(w => !set2.has(w))
      .sort((a, b) => a.localeCompare(b));

    const uniqueToBook2 = [...set2]
      .filter(w => !set1.has(w))
      .sort((a, b) => a.localeCompare(b));

    const commonWords = [...set1]
      .filter(w => set2.has(w))
      .sort((a, b) => a.localeCompare(b));

    res.json({
      uniqueToBook1,
      uniqueToBook2,
      commonWords
    });
  } catch (err) {
    console.error('Error comparing books:', err);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

app.get('/word-chart-app/api/chart-data/:title/:n', async (req, res) => {
  const { title, n } = req.params;
  const { filter = 'basic' } = req.query;

  try {
    const redisKey = `book:${title}:word_counts`;
    // TODO 5: read every field and value of the hash redisKey, as in TODO 3.
    const wordMap = {};

    if (!wordMap || Object.keys(wordMap).length === 0) {
      return res.status(404).json({ error: 'Book not found.' });
    }

    let wordEntries = Object.entries(wordMap)
      .map(([word, count]) => ({
        word,
        count: parseInt(count)
      }));

    wordEntries = filterWords(wordEntries, filter);

    wordEntries.sort((a, b) => b.count - a.count);
    wordEntries = wordEntries.slice(0, parseInt(n));
    res.json({
      labels: wordEntries.map(e => e.word),
      counts: wordEntries.map(e => e.count)
    });
  } catch (err) {
    console.error('Error generating chart data:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// Start server and index books. 0.0.0.0 so the browser on your computer can reach it.
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`Server running at http://127.0.0.1:${PORT}/word-chart-app/`);
  await indexBooks();
});
