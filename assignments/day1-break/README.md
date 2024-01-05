

chmod to setup

### SQL

While Pandas is undoubtedly a useful tool and is great for exploring small datasets. There are a number of cases where it may not be the right tool for the task. 

Pandas runs exclusively in memory. With even moderately sized data you may exceed available memory. Additionally, pandas materializes each intermediate result, so the memory consumption can easily reach several times your input data if you are not very careful. Materializing after each operation is also inefficient, even when data fits in memory. If you want to save results, you have to manage a set of output files. With small data sets like we show in this lab, this is not a problem, but as your datasets grow larger or more complex this becomes an increasingly difficult task.

Furthermore, above we had to define all of the physical operations to transform the data. Choosing to or add or remove columns, the order to apply filters, etc.

An alternative to this approach is to use a Database Management System (DBMS) like Postgres or SQLite that supports a declarative query language. Unlike Pandas, a DBMS can usually store data that far exceeds what you can hold in memory. Users most often interact with DBMSs through a declarative query language, typically a dialect of SQL. Unlike pandas, in SQL you define what data to retrieve, instead of the physical operations to retrieve it. This allows the DMBS to automatically optimize your query, choosing the order to apply filters, how to apply predicates, etc.

However, using a DBMS is typically a little harder to get going with. You have to define a schema for the tables you work with, and load all the data in before you can start querying it. If you are doing a one off analysis on some small CSV you downloaded, it is probably easier to use Pandas. If you have some special operation that the DBMS does not natively support, a linear regression for instance, doing this inside a DBMS can be cumbersome. 

In this section we will introduce you to a simple DBMS called SQLite. Perhaps the [2nd most deployed software package](https://www.sqlite.org/mostdeployed.html) of all time! Unlike most DBMSs which run all the time and are accessed over a network. SQLite runs as a library in the same process as your program and stores all it's state in a single file. This makes it easy to deploy, use, and play around with SQL.


#### 1. Exploring the Schema

We give you a database file (`imdb.db`) in which the csv files have been loaded using the `load_data.sql` command.


In the bash shell (in the container), let's open a sqlite shell and have a look at our data. The ``-column -header`` settings pretty print the output into columns with a header. We can see the tables loaded into the database by running ``.tables`` and the schema of these tables with ``.schema [tablename]``. We will then run our first sql query to fetch the first few rows of the titles tables. Note that typically table names, column names, and SQL keywords are not case sensitive.

```sh
root@40ce47bd550e:/lab1# sqlite3 data/imdb.db -column -header
SQLite version 3.31.1 2020-01-27 19:55:54
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
sqlite> SELECT * FROM titles LIMIT 5;
title_id    type        primary_title   original_title     is_adult    premiered   ended       runtime_minutes  genres
----------  ----------  --------------  -----------------  ----------  ----------  ----------  ---------------  ----------
tt0011216   movie       Spanish Fiesta  La fête espagnole  0           2019                    67               Drama
tt0011801   movie       Tötet nicht me  Tötet nicht mehr   0           2019                                     Action,Cri
tt0040241   short       Color Rhapsodi  Color Rhapsodie    0           2021                    6                Short
tt0044326   short       Abstronic       Abstronic          0           2021                    6                Short
tt0044879   short       Mandala         Mandala            0           2021                    3                Short
``` 

#### 2. Filtering & Aggregation

Now let's get the same data as we did with pandas and see how it looks in SQL. For simplicity, we'll write our queries in a text file ``scratch.sql`` with a text editor and run the SQL query in the file by running ``.read scratch.sql``. We'll show both the query and results separated by ``+++++++++++++++++++++++`` below. We'll start by looking at the average duration.

```sql
SELECT
        AVG(runtime_minutes)
FROM
        titles;

+++++++++++++++++++++++

sqlite> .read scratch.sql
AVG(runtime_minutes)
--------------------
39.2196530669821
```


This matches the result we got from pandas so we are on the right track. We can also aggregate columns simultaneously.

```sql
SELECT
        MAX(premiered),
        MAX(runtime_minutes),
        COUNT(DISTINCT genres) AS num_genres -- Compute the number of unique genres.
FROM
        titles;

+++++++++++++++++++++++

sqlite> .read scratch.sql
MAX(premiered)  MAX(runtime_minutes)  num_genres
--------------  --------------------  ----------
2029            43200                 1876
```

Now as above we'll group by release year again.

```sql
SELECT 
        premiered,
        MAX(runtime_minutes)
FROM 
        titles
GROUP BY 
        premiered;

+++++++++++++++++++++++

sqlite> .read scratch.sql
premiered   MAX(runtime_minutes)
----------  --------------------
2015        6000
2016        2070
2017        5760
2018        7777
2019        28643
2020        43200
2021        6000
2022        400
2023        240
2024        360
2025        125
2026        360
2027        360
2028
2029        14
```
   
and order by descending. Let's just get the first few rows by using ``LIMIT``;

```sql
SELECT 
        premiered,
        MAX(runtime_minutes) AS max_runtime
FROM 
        titles
GROUP BY 
        premiered
ORDER BY
        max_runtime DESC
LIMIT 5;

+++++++++++++++++++++++

sqlite> .read scratch.sql
premiered   max_runtime
----------  -----------
2020        43200
2019        28643
2018        7777
2021        6000
2015        6000
```
        
Like we did with pandas we can also find the ratings that are greater than 9 with more than 100 votes. We'll do that using a `WHERE` clause.

```sql
SELECT 
        *
FROM 
        ratings
WHERE 
        rating >= 9 AND votes >= 100
LIMIT 5;

++++++++++++++++++++++++++++

sqlite> .read scratch.sql
title_id    rating      votes
----------  ----------  ----------
tt10001184  9.1         1400
tt10001588  9           155
tt10005284  9.2         1503
tt10008916  9.7         3321
tt10008922  9.4         1666
```

We'll again join these ratings with their corresponding movies.

#### 3. Joining
To join two or more tables, we first list them in the `FROM` clause. We specify how to join in the `WHERE` clause. The `WHERE` clause may further contain additional filters for each individual tables.

Here is how to compute in SQL the same join we computed using pandas:

```sql
SELECT 
        t.primary_title, t.premiered, r.rating, r.votes
FROM 
        titles AS t, ratings AS r
WHERE
        t.title_id = r.title_id -- Join condition 
        AND t.type = 'movie'
        AND r.rating >= 9 AND r.votes >= 100
ORDER BY
    r.rating DESC
LIMIT 10;
                      
+++++++++++++++++++++++

sqlite> .read scratch.sql
primary_title  premiered   rating      votes
-------------  ----------  ----------  ----------
Hulchul        2019        10          754
Days of Géant  2019        10          205
Days of Géant  2020        10          188
Veyi Subhamul  2022        10          1909
The Silence o  2021        10          4885
Ajinkya        2021        9.9         747
Tari Sathe     2021        9.9         446
Rite of the S  2022        9.9         121
Maa Kathalu    2021        9.9         708
Half Stories   2022        9.9         1699
```    

We now discuss a few useful SQL-only features.


#### 4. Common Table Expressions
Common Table Expressions (CTEs) are a useful mechanism to simplify complex queries. They allow us to precompute temporary tables that can be used in other parts of the queries. While the join above is not complex enough to warrent using CTEs, we will use it as an example to get you started. Suppose that, like in our pandas example, we wanted to first compute the set of excellent ratings and the set of movies before joining them.

```sql
WITH 
excellent (title_id, rating, votes) AS ( -- Precompute excellent ratings
        SELECT * FROM ratings WHERE rating >= 9 AND votes >= 100
),
movies (title_id, primary_title, premiered) AS ( -- Precomputed movies
        SELECT title_id, primary_title, premiered FROM titles WHERE type='movie'
)

SELECT rating, votes, primary_title, premiered  -- Join them.
FROM excellent AS e, movies AS m
WHERE e.title_id = m.title_id
ORDER BY rating LIMIT 10;

+++++++++++++++++++++++++++

rating      votes       primary_title  premiered
----------  ----------  -------------  ----------
10          754         Hulchul        2019
10          205         Days of Géant  2019
10          188         Days of Géant  2020
10          1909        Veyi Subhamul  2022
10          4885        The Silence o  2021
9.9         747         Ajinkya        2021
9.9         446         Tari Sathe     2021
9.9         121         Rite of the S  2022
9.9         708         Maa Kathalu    2021
9.9         1699        Half Stories   2022
```

In this query, we first compute the table of excellent ratings and the table of movies using the construct `WITH table_name(column_names...) AS (query)`. We then perform the join using these temporary tables. 


### Questions


1. (Simple aggregation and ordering) Using the crew table, compute the number of distinct actors and actresses. Return the category (`actor` or `actress`) and the count for each category. Order by category (ascending).
2. (Simple filtering and join) Find the action TV shows (`titles.type=tvSeries` and `titles.genres` contains `Action`) released in 2021, with a rating >= 8 and at least 100 votes. Return title_id, name, and rating. Order by rating (descending) and then name (ascending) to break ties.
3. (Simple aggregation and join) Find the movie (`titles.type=movie`) with the most actors and actresses (cumulatively). If multiple movies are tied, return the one with the alphabetically smallest primary title. Return the title_id, primary title, and number of actors.
4. (Simple subquery/CTE) Find the movie with the most actors and actresses (cumulatively). Unlike in question (3), you should return all such movies. Again, return the title_id, primary title and number of actors. Order by primary title (ascending).