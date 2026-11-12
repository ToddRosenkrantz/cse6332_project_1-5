#!/bin/sh
# Download the three books from Project Gutenberg into books/ (run inside the container):
#   docker exec cse6332-course sh /data/word-count-app/fetch_books.sh
# The file name (without .txt) is the title the pages show.
cd "$(dirname "$0")" && mkdir -p books
get() { curl -fsSL -o "books/$2.txt" "https://www.gutenberg.org/cache/epub/$1/pg$1.txt" && echo "books/$2.txt"; }
get 1342 Pride_and_Prejudice
get 2600 War_and_Peace
get 78   Tarzan_of_the_Apes
