# Assignment 1: Experimenting with SQL

In this first assignment we will introduce you to a simple DBMS called SQLite - perhaps among the [top 5 most deployed software packages](https://www.sqlite.org/mostdeployed.html) of all time! Unlike most DBMSs which run all the time and are accessed over a network. SQLite runs as a library in the same process as your program and stores all its state in a single file. This makes it easy to deploy, use, and play around with SQL. We will use SQLite to run some simple SQL queries - you can then feel free to create even more involved queries to better hone your SQL skills!

## Table of Contents
- [Setup](#setup)
- [Exploration](#exploration)
  * [Exploring the Schema](#1-exploring-the-schema)
  * [Filtering and Aggregation](#2-filtering--aggregation)
  * [Joining](#3-joining)
  * [Common Table Expressions (CTEs)](#4-common-table-expressions)
- [Questions](#questions)


## Setup

Before starting, make sure you have activated the python virtual environment for these assignments, by running the following command from within this directory:

```
source ../iap-data-venv/bin/activate
```

We will be populating our databse with part of the [IMDB dataset](https://developer.imdb.com/non-commercial-datasets/), which contains information about movies, actors etc. from [IMDB](https://www.imdb.com/). Because the full dataset is large, we have selected a subset including only information relevant for movies released in 2020. We have loaded this part of the dataset into a SQLite database and compressed the resulting file for easier distribution, leading to `datasets/imdb/imdb-2020-db.tar.gz`. From within this directory, run the following command to decompress the file:

```
tar -xzvf ../datasets/imdb/imdb-2020-db.tar.gz -C ../datasets/imdb
```

(Optional) If you would like to download and use the full IMDB dataset instead, you can use the following command from within this directory (heads up, this will take several minutes and use up around 14 GB). This will create a file called `datasets/imdb/imdb.db`.

```
imdb-sqlite --cache-dir ../datasets/imdb/ --db ../datasets/imdb/imdb.db
```

[*Back to top*](#table-of-contents)

## Exploration

### 1. Exploring the Schema

In a bash shell, let's connect to sqlite and have a look at our data. The ``-column -header`` settings pretty print the output into columns with a header. We can see the tables loaded into the database by running ``.tables`` and the schema of these tables with ``.schema [tablename]``. We will then run our first sql query to fetch some fields of the first few rows of the titles tables. Note that typically table names, column names, and SQL keywords are not case sensitive.

```sh
(iap-data-venv) ~/iap-class/assignments$ sqlite3 ../datasets/imdb/imdb-2020.db -column -header
SQLite version 3.37.2 2022-01-06 13:25:41
Enter ".help" for usage hints.
sqlite> .tables
akas      crew      episodes  people    ratings   titles  
sqlite> .schema titles
CREATE TABLE IF NOT EXISTS "titles"(
  title_id TEXT,
  type TEXT,
  primary_title TEXT,
  original_title TEXT,
  is_adult INT,
  premiered INT,
  ended INT,
  runtime_minutes INT,
  genres TEXT
);
CREATE INDEX ix_titles_type ON titles (type);
CREATE INDEX ix_titles_primary_title ON titles (primary_title);
CREATE INDEX ix_titles_original_title ON titles (original_title);
sqlite> SELECT title_id,type,primary_title,runtime_minutes FROM titles LIMIT 5;
title_id   type      primary_title                                       runtime_minutes
---------  --------  --------------------------------------------------  ---------------
tt0060366  short     A Embalagem de Vidro                                11             
tt0062336  movie     The Tango of the Widower and Its Distorting Mirror  70             
tt0166938  tvSeries  Yo-TV                                                              
tt0206169  short     The News No. 3                                      3              
tt0214297  short     The Way to Shadow Garden                            10     
``` 

[*Back to top*](#table-of-contents)

### 2. Filtering & Aggregation

Now let's start applying simple functions to the data. We'll show both the query and results below. We'll start by looking at a simple aggregate - the average duration:

```sql
sqlite> SELECT AVG(runtime_minutes) 
FROM titles;

AVG(runtime_minutes)
--------------------
40.5470974391903  
```

We can also aggregate over multiple columns simultaneously.

```sql
sqlite> SELECT MAX(runtime_minutes), COUNT(DISTINCT genres) AS num_genres 
FROM titles;

MAX(runtime_minutes)  num_genres
--------------------  ----------
43200                 1244      
```

Additionally, we can calculate aggregates in each group, using `GROUP BY`, and apply sorting using `ORDER BY`. Let's just get the first few rows by using ``LIMIT``:

```sql
sqlite> SELECT genres,MAX(runtime_minutes) AS max_runtime 
FROM titles 
GROUP BY genres 
ORDER BY max_runtime DESC 
LIMIT 10;

genres                  max_runtime
----------------------  -----------
Documentary             43200      
Adventure,Documentary   13319      
\N                      12000      
Talk-Show               6000       
Comedy,Music,News       2520       
Crime,Documentary       2020       
Comedy,Talk-Show        1845       
Biography,Comedy,Drama  1594       
Comedy,Drama,Sport      1453       
Drama                   1325        
```

Beyond aggregation, we can apply filtering using a `WHERE` clause.

```sql
sqlite> SELECT * 
FROM ratings 
WHERE rating >= 9 AND votes >= 100 
ORDER BY rating DESC, votes DESC 
LIMIT 5;

title_id    rating  votes
----------  ------  -----
tt30151030  10      114  
tt13555390  10      104  
tt15875180  10      100  
tt11028174  9.9     20545
tt9313978   9.9     17664  
```

[*Back to top*](#table-of-contents)

### 3. Joining

The rating information we just retrieved is based on `title_id`, which is not a very human-interpretable field. To find the corresponding movie titles, we need to join these ratings with their corresponding movies.


To join two or more tables, we first list them in the `FROM` clause. We specify how to join in the `WHERE` clause. The `WHERE` clause may further contain additional filters for each individual tables.

Here is the resulting query:

```sql
sqlite> SELECT t.primary_title, r.rating, r.votes 
FROM titles AS t, ratings AS r 
WHERE t.title_id = r.title_id AND rating >= 9 AND votes >= 100 
ORDER BY rating DESC, votes DESC 
LIMIT 5;
                      
primary_title                                                      rating  votes
-----------------------------------------------------------------  ------  -----
Take 69 B                                                          10      114  
BJ Korros/JoJo Siwa at The 84th Annual Hollywood Christmas Parade  10      104  
All Over the World: Yamashita Tomohisa to sekai de deau            10      100  
The View from Halfway Down                                         9.9     20545
Victory and Death                                                  9.9     17664
```    

[*Back to top*](#table-of-contents)

### 4. Common Table Expressions
Common Table Expressions (CTEs) are a useful mechanism to simplify complex queries. They allow us to precompute temporary tables that can be used in other parts of the queries. While the join above is not complex enough to warrent using CTEs, we will use it as an example to get you started. Suppose that we wanted to first compute the set of excellent ratings and the set of movies before joining them.

```sql
sqlite> WITH 
excellent (title_id, rating, votes) AS ( 
        SELECT * 
        FROM ratings 
        WHERE rating >= 9 AND votes >= 100 
        ORDER BY rating DESC 
        LIMIT 5
)
SELECT primary_title, rating, votes
FROM excellent AS e, titles AS t
WHERE e.title_id = t.title_id;

primary_title                                                      rating  votes
-----------------------------------------------------------------  ------  -----
BJ Korros/JoJo Siwa at The 84th Annual Hollywood Christmas Parade  10      104  
All Over the World: Yamashita Tomohisa to sekai de deau            10      100  
Take 69 B                                                          10      114  
The View from Halfway Down                                         9.9     20545
Equipe E 
```

In this query, we first compute the table of excellent titles using the construct `WITH table_name(column_names...) AS (query)`. We then perform the join using this temporary table. 

[*Back to top*](#table-of-contents)


## Questions


1. (Simple aggregation and ordering) Using the `crew` table, compute the number of distinct actors and actresses. Return the category (`actor` or `actress`) and the count for each category. Order by category (ascending).
2. (Simple filtering and join) Find the action TV shows (`titles.type=tvSeries` and `titles.genres` contains `Action`) with a rating >= 8 and at least 100 votes. Return `title_id`, `name`, and `rating`. Order by `rating` (descending) and then `name` (ascending) to break ties.
3. (Simple aggregation and join) Find the movie (`titles.type=movie`) with the most actors and actresses (cumulatively). If multiple movies are tied, return the one with the alphabetically smallest `primary_title`. Return the `title_id`, `primary_title`, and number of actors.
4. (Simple subquery/CTE) Find the movie with the most actors and actresses (cumulatively). Unlike in question (3), you should return all such movies. Again, return the `title_id`, `primary_title` and number of actors. Order by `primary_title` (ascending).

[*Back to top*](#table-of-contents)