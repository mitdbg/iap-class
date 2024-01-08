# Assignment 2: Experimenting with Pandas

In this second assignment, we will use pandas to perform similar tasks as assignment 1. Pandas is one of the most popular tools for working with relatively small datasets (i.e. that fit in the main memory of a single machine). It uses an abstraction called dataframes to manipulate tabular data. It natively supports reading data from a variety of common file formats including CSVs, fixed-width files, columnar formats, HDF5, and JSON. It also allows you to import data from common database management systems (DBMSs). A comprehensive list is [here](https://pandas.pydata.org/pandas-docs/stable/reference/io.html).

## Table of Contents
- [Setup](#setup)
- [Exploration](#exploration)
  * [Reading and Parsing Files](#1-reading-and-parsing-files)
  * [Filtering and Aggregation](#2-filtering--aggregation)
  * [Joining](#3-joining)
- [Questions](#questions)

## Setup

Before starting, make sure you have activated the python virtual environment for these assignments, by running the following command from within this directory:

```
source ../iap-data-venv/bin/activate
```

We will be using CSV files derived from the part of the [IMDB dataset](https://developer.imdb.com/non-commercial-datasets/) also used in assignment 1. We have compressed the files for easier distribution, leating to `datasets/imdb/imdb-2020-files.tar.gz`. From within this directory, run the following command to decompress the files:

```
tar -xzvf ../datasets/imdb/imdb-2020-files.tar.gz -C ../datasets/imdb
```

[*Back to top*](#table-of-contents)

## Exploration

### 1. Reading and parsing files
First, let's have a look at the first few lines of the data file for IMDB titles:

```bash
(iap-data-venv) ~/iap-class/assignments$ head ../datasets/imdb/titles.csv
title_id,type,primary_title,original_title,is_adult,premiered,ended,runtime_minutes,genres
tt0060366,short,"A Embalagem de Vidro","A Embalagem de Vidro",0,2020,,11,"Documentary,Short"
tt0062336,movie,"The Tango of the Widower and Its Distorting Mirror","El tango del viudo y su espejo deformante",0,2020,,70,Drama
tt0166938,tvSeries,Yo-TV,Yo-TV,0,2020,,,\N
tt0206169,short,"The News No. 3","The News No. 3",0,2020,,3,Short
tt0214297,short,"The Way to Shadow Garden","The Way to Shadow Garden",0,2020,,10,Short
tt0230622,movie,Parinati,Parinati,0,2020,,125,Drama
tt0280237,tvSeries,"Big Brother","Big Brother",0,2020,,,"Game-Show,Reality-TV"
tt0293513,movie,"Pit Bull: A Tale of Lust, Murder and Revenge","Pit Bull",0,2020,,,\N
tt0296388,tvSeries,"Norge i dag","Norge i dag",0,2020,,20,News
```

Let's open a python shell, import pandas, load the data and have a look. (Note: to exit the python shell, you can use `exit()` or Ctrl+D)

```sh
(iap-data-venv) ~/iap-class/assignments$ python3
Python 3.10.12 (main, Nov 20 2023, 15:14:05) [GCC 11.4.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
```
```py
>>> import pandas as pd
>>> titles = pd.read_csv("../datasets/imdb/titles.csv")
>>> titles
         title_id      type                                      primary_title  ... ended  runtime_minutes                     genres
0       tt0060366     short                               A Embalagem de Vidro  ...   NaN             11.0          Documentary,Short
1       tt0062336     movie  The Tango of the Widower and Its Distorting Mi...  ...   NaN             70.0                      Drama
2       tt0166938  tvSeries                                              Yo-TV  ...   NaN              NaN                         \N
3       tt0206169     short                                     The News No. 3  ...   NaN              3.0                      Short
4       tt0214297     short                           The Way to Shadow Garden  ...   NaN             10.0                      Short
...           ...       ...                                                ...  ...   ...              ...                        ...
413325  tt9914924     short                                        Been Broken  ...   NaN             19.0       Comedy,Drama,Romance
413326  tt9915110     short                                Say Yes to Continue  ...   NaN              3.0              Mystery,Short
413327  tt9916190     movie                                          Safeguard  ...   NaN             95.0  Action,Adventure,Thriller
413328  tt9916270     movie                           Il talento del calabrone  ...   NaN             84.0                   Thriller
413329  tt9916362     movie                                              Coven  ...   NaN             92.0              Drama,History

[413330 rows x 9 columns]
```

Note that Pandas represents all strings as object types and automatically recognizes integers and floats. You can check the data types of each dataframe column by using `.dtypes`:

``` py
>>> titles.dtypes
title_id            object
type                object
primary_title       object
original_title      object
is_adult             int64
premiered            int64
ended              float64
runtime_minutes    float64
genres              object
dtype: object
```

[*Back to top*](#table-of-contents)

### 2. Filtering & Aggregation
Now let's get to answering the same simple questions as in assignment 1! We select the `runtime_minutes` column and compute the mean over it as follows:

```py
>>> titles['runtime_minutes'].mean()
40.547097439190274
```

We can also aggregate over multiple columns simultaneously, by selecting them and then providing `.agg()` with a dictionary of the aggregation functions:

```py
>>> titles[["runtime_minutes", "genres"]].agg({"runtime_minutes":"max", "genres": lambda x: x.nunique()})
runtime_minutes    43200.0
genres              1244.0
dtype: float64
```

To calculate aggregates within group, we can use `groupby()`, while to sort by a column we can use `sort_values()`. The role of SQL's `LIMIT` can be played by `head()`: 


```py
>>> df = titles.groupby('genres').agg({"runtime_minutes":"max"}).sort_values("runtime_minutes", ascending=False).head(10)
>>> df
                        runtime_minutes
genres                                 
Documentary                     43200.0
Adventure,Documentary           13319.0
\N                              12000.0
Talk-Show                        6000.0
Comedy,Music,News                2520.0
Crime,Documentary                2020.0
Comedy,Talk-Show                 1845.0
Biography,Comedy,Drama           1594.0
Comedy,Drama,Sport               1453.0
Drama                            1325.0
```

After aggregation, the columns of the dataframe are in a different format: group by columns are now treated as indices and aggregate columns have a subcolumn for each aggregate, if one uses multiple aggregates. This makes them more difficult to manipulate. You can restore the default format of dataframes as follows:

```py
>>> df.columns = ['runtime_minutes_max']
>>> df = df.reset_index()
>>> df
                   genres  runtime_minutes_max
0             Documentary              43200.0
1   Adventure,Documentary              13319.0
2                      \N              12000.0
3               Talk-Show               6000.0
4       Comedy,Music,News               2520.0
5       Crime,Documentary               2020.0
6        Comedy,Talk-Show               1845.0
7  Biography,Comedy,Drama               1594.0
8      Comedy,Drama,Sport               1453.0
9                   Drama               1325.0
```

Beyond aggregation, we can apply filtering on the desired column(s):

```py
>>> ratings = pd.read_csv("../datasets/imdb/ratings.csv")
>>> ratings[(ratings['rating'] >= 9) & (ratings['votes'] >= 100)].sort_values(by=['rating', 'votes'], ascending=[False, False]).head(5)
         title_id  rating  votes
51028  tt30151030    10.0    114
43570  tt13555390    10.0    104
49664  tt15875180    10.0    100
4194   tt11028174     9.9  20545
54275   tt9313978     9.9  17664
```

It's worth taking a moment to see what is going on here. When we filter a dataset this way, we first create a boolean mask. We then use this mask to filter the data.

```py
>>> ratings['rating'] >= 9
0        False
1        False
2        False
3        False
4        False
         ...  
55452    False
55453    False
55454    False
55455    False
55456    False
Name: rating, Length: 55457, dtype: bool
```
        
We can then combine these vectors with boolean operations (&, |), as we did above.

[*Back to top*](#table-of-contents)

### 3. Joining

As in assignment 1, the rating information we just retrieved is based on `title_id`, which is not a very human-interpretable field. To find the corresponding movie titles, we need to join these ratings with their corresponding movies. We will do this in two steps. First, we find all ratings greater than 9 with at least 100 votes:

```py
>>> excellent = ratings[(ratings['rating'] >= 9) & (ratings['votes'] >= 100)]
>>> excellent
         title_id  rating  votes
118    tt10042144     9.0   2177
195    tt10065388     9.2   1825
196    tt10065390     9.3   2400
248    tt10084334     9.4   4639
1095   tt10322300     9.1   3729
...           ...     ...    ...
54890   tt9686346     9.6    333
54951   tt9699204     9.0   6817
54956   tt9700192     9.2   3619
55064   tt9729172     9.0   9949
55330   tt9853400     9.2   1367

[376 rows x 3 columns]
```

Now that we have our filtered list of excellent ratings, we can proceed to the join. Pandas has a "merge" function for this purpose that we'll use to join the two dataframes. A join takes rows from one dataframe, matches them with rows in another dataframe based on a condition, and outputs a new "merged" dataframe. Here we will join the two dataframes on their `title_id` column. 

```py
>>> merged = pd.merge(left=titles, right=excellent, on='title_id')[['primary_title', 'rating', 'votes']]
>>> merged
                primary_title  rating  votes
0                        Polo     9.0   2177
1    Start Spreading the News     9.2   1825
2                Happy Ending     9.3   2400
3          A Dark Quiet Death     9.4   4639
4                  Lights Out     9.1   3729
..                        ...     ...    ...
371           Chasing the Sun     9.6    333
372                 Episode 7     9.0   6817
373                   Fadeout     9.2   3619
374              Walk with Us     9.0   9949
375                  Hype Man     9.2   1367

[376 rows x 3 columns]
```

Now let's find the top 5 of these movies with the highest rating, breaking ties in favor of more votes:
```py
>>> merged.sort_values(by=['rating', 'votes'], ascending=[False, False]).head(5)
                                         primary_title  rating  votes
329                                          Take 69 B    10.0    114
286  BJ Korros/JoJo Siwa at The 84th Annual Hollywo...    10.0    104
325  All Over the World: Yamashita Tomohisa to seka...    10.0    100
26                          The View from Halfway Down     9.9  20545
366                                  Victory and Death     9.9  17664
```

There are a lot of things you can do with Pandas that we have not covered, including different kinds of aggregation, plots, joins, input and output formats, etc. You are encouraged to use [online resources](https://pandas.pydata.org/docs/index.html) to explore this for yourself.

[*Back to top*](#table-of-contents)

## Questions

1. Using the `crew` table, compute the number of distinct actors and actresses. Return the category (`actor` or `actress`) and the count for each category. Order by category (ascending).
2. Find the action TV shows (`titles.type=tvSeries` and `titles.genres` contains `Action`) with a rating >= 8 and at least 100 votes. Return `title_id`, `name`, and `rating`. Order by `rating` (descending) and then `name` (ascending) to break ties.
3. Find the movie (`titles.type=movie`) with the most actors and actresses (cumulatively). If multiple movies are tied, return the one with the alphabetically smallest `primary_title`. Return the `title_id`, `primary_title`, and number of actors.
4. Find the movie with the most actors and actresses (cumulatively). Unlike in question (3), you should return all such movies. Again, return the `title_id`, `primary_title` and number of actors. Order by `primary_title` (ascending).
5. Find the actors/actresses who played in the largest number of movies. The result set may contain one or many persons. Return the category ('actor' or 'actress'), the name, and the number of appearances. Order the results by name (ascending). Use the `people` table to get the name of actors.
6. Find the actors/actresses with at least 5 movies that have the highest average ratings on their movies. Return the name, the number of titles and the average rating. Order the results by average rating (descending) and then name (ascending).

[*Back to top*](#table-of-contents)
