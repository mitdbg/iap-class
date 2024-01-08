# Assignment 3: Data Cleaning

In this assignment, you will deal with the all-too-frequent problem of bringing your data into a format that makes analysis possible. The two parts of the lab will take you through several  tasks commonly involved in this process:
- In part 1, you will use the command line tools `sed` and `awk` to efficiently clean and transform data originating in inconvenient formats.
- In part 2, you will deal with the issue of missing values, examining appropriate ways to impute them based on your intended analysis.

Let's get started!

## Table of Contents
- [Setup](#setup)
- [Datasets](#datasets)
- [Part 1: Unix tools](#part-1-unix-tools)
  * [General-purpose tools](#general-purpose-tools)
  * [Tool 1: grep](#tool-1-grep)
  * [Tool 2: sed](#tool-2-sed)
  * [Tool 3: awk](#tool-3-awk)
  * [Examples](#examples)
  * [Part 1 Questions](#part-1-questions)
- [Part 2: Missing value imputation](#part-2-missing-value-imputation)
  * [Exploring the data](#exploring-the-data)
  * [Part 2 Questions](#part-2-questions)


## Setup

Before starting, make sure you have activated the python virtual environment for these assignments, by running the following command from within this directory:

```
source ../iap-data-venv/bin/activate
```

## Datasets

The `datasets/cleaning` directory contains 7 datasets. Here is a quick overview:

1. `crime-clean.txt`: A dataset of the reported crime rate in each US state + D.C., for each year between 2004 and 2008, inclusive.

2. `crime-unclean.txt`: A version of `crime-clean.txt` where some data is missing.

3. `labor.csv`: A small dataset of labor information, with each field of each record presented on a separate line.

4. `salaries.csv`: A dataset resulting from a [web survey of salaries](https://data.world/brandon-telle/2016-hacker-news-salary-survey-results) for different positions.

5. `twitter.json.gz`: A dataset of tweets, compressed using `gzip`.

6. `worldcup-semiclean.txt`: A partially cleaned-up version of `worldcup.txt`, after removing wiki source keywords and other formatting.

7. `worldcup.txt`: A snippet of the following Wikipedia webpage on the [FIFA (Soccer) World Cup](https://en.wikipedia.org/wiki/FIFA_World_Cup#Teams_reaching_the_top_four), corresponding to the table toward the end of the page that lists teams finishing in the top 4. 

[*Back to top*](#table-of-contents)

## Part 1: Unix tools 

The set of three `UNIX` tools we saw in class, `sed`, `awk`, and `grep`, can be very useful for quickly cleaning up and transforming data for further analysis (and have been around since the inception of UNIX). 

In conjunction with other unix utilities like `sort`, `uniq`, `tail`, `head`, `paste`, etc., you can accomplish many simple data parsing and cleaning  tasks with these tools. 

You are encouraged to play with these tools and familiarize yourselves with their basic usage.

As an example, the following sequence of commands can be used to answer the question "Find the five twitter user ids (uids) that have tweeted the most".  Note that in the example below, we're using the `zgrep` variant of `grep`, which allows us to operate over [gzipped data](https://en.wikipedia.org/wiki/Gzip).
```bash
(iap-data-venv) ~/iap-class/assignments$ zgrep "created\_at" ../datasets/cleaningsets/cleaning/twitter.json.gz \
   | sed 's/"user":{"id":\([0-9]*\).*/XXXXX\1/' \
   | sed 's/.*XXXXX\([0-9]*\)$/\1/' \
   | sort \
   | uniq -c \
   | sort -n \
   | tail -5
```

The first stage (`zgrep`) discards the deleted tweets, the `sed` commands extract the first "user-id" from each line, `sort` sorts the user ids, and `uniq -c` counts the unique entries (*i.e.,* user ids). The final `sort -n | tail -5` return the top 5 uids.

Note that, combining the two `sed` commands as follows does NOT do the right thing -- we will let you figure out why.

```bash
(iap-data-venv) ~/iap-class/assignments$ zgrep "created\_at" ../datasets/cleaningsets/cleaning/twitter.json.gz \
  | sed 's/.*"user":{"id":\([0-9]*\).*/\1/' \
  | sort \
  | uniq -c \
  | sort -n \
  | tail -5
```

To get into some details:

### General-purpose tools

- `cat` can be used to list the contents of a file:

```bash
(iap-data-venv) ~/iap-class/assignments$ cat ../datasets/cleaning/worldcup-semiclean.txt
!Team!!Titles!!Runners-up!!Thirdplace!!Fourthplace!!|Top4Total
|-
BRA
|1958,1962,1970,1994,2002
|1950,1998
...
```

- `tail` is in the same vein, but provides the convenient option of specifying the (1-indexed) starting line. This can be useful when e.g. omitting the header of a CSV file:

```bash
(iap-data-venv) ~/iap-class/assignments$ tail +3 ../datasets/cleaning/worldcup-semiclean.txt
BRA
|1958,1962,1970,1994,2002
|1950,1998
...
```

- Similar to how `tail` can help us omit lines, `cut` can help us omit fields. We can use `-d` to specify the delimiter and `-f` to pick one or more fields to print. By using `--complement -f` we can instead specify which field(s) to *not* print.

```bash
(iap-data-venv) ~/iap-class/assignments$cut -d "," -f 1 ../datasets/cleaning/salaries.csv | tail -5
1093
1094
1097
1098
1100
```

-  `sort` can be used to sort the lines of a text file. It provides many useful flags for specifying things like case sensitivity, sort key location (i.e. which filed in each line to sort by) etc. You can see the complete list of flags using `sort --help`

- `uniq` can be used to remove *adjacent* duplicate lines from a file. Specifying the flag `-c` will prepend the count of such duplicates to each printed line.

- `wc` can be used to count characters (`-c`), words (`-w`) or lines (`-l`) in a text file.

### Tool 1: `grep`

The basic syntax for `grep` is: 
```bash
$ grep 'regexp' filename
```
or equivalently (using UNIX pipelining):
```bash
$ cat filename | grep 'regexp'
```

The output contains only those lines from the file that match the regular expression. Two options to grep are useful: `grep -v` will output those lines that *do not* match the regular expression, and `grep -i` will ignore case while matching. See the manual (`man grep`) or online resources for more details.

### Tool 2: `sed`
Sed stands for _stream editor_. Basic syntax for `sed` is:
```bash
$ sed 's/regexp/replacement/g' filename
```

For each line in the input, the portion of the line that matches _regexp_ (if any) is replaced with _replacement_. `sed` is quite powerful within the limits of operating on single line at a time. You can use `\(\)` to refer to parts of the pattern match. In the first sed command above, the sub-expression within `\(\)` extracts the user id, which is available to be used in the _replacement_ as `\1`. 

As an example, the command below is what we used to clean `worldcup.txt` and produce `worldcup-semiclean.txt`:

```bash
(iap-data-venv) ~/iap-class/assignments$ cat ../datasets/cleaning/worldcup.txt \
  | sed \
    's/\[\[\([0-9]*\)[^]]*\]\]/\1/g;
    s/.*fb|\([A-Za-z]*\)}}/\1/g; 
    s/data-sort[^|]*//g;
    s/<sup><\/sup>//g;
    s/<br \/>//g;
    s/|style=[^|]*//g;
    s/|align=center[^|]*//g;
    s/|[ ]*[0-9] /|/g;
    s/.*div.*//g;
    s/|[a-z]*{{N\/a|}}/|0/g;
    s|[()]||g;
    s/ //g;
    /^$/d;' > ../datasets/cleaning/worldcup-semiclean.txt
```

### Tool 3: `awk` 

Finally, `awk` is a powerful scripting language. The basic syntax of `awk` is: 
```bash
$ awk -F',' \
  'BEGIN{commands}
  /regexp1/ {command1}
  /regexp2/ {command2}
  END{commands}' 
```

For each line, the regular expressions are matched in order, and if there is a match, the corresponding command is executed (multiple commands may be executed for the same line). `BEGIN` and `END` are both optional. The `-F','` specifies that the lines should be _split_ into fields using the separator `','` (single comma), and those fields are available to the regular expressions and the commands as `$1`, `$2`, etc.  See the manual (`man awk`) or online resources for further details. 

### Examples 

A few examples to give you a flavor of the tools and what one can do with them. Make sure that you go through them, since some of the idioms used will be helpful for the questions that follow.

1. Merge consecutive groups of lines referring to the same record on `labor.csv` (a process sometimes called a *wrap*).

   We keep a "running record" in `combined`, which we print and re-intialize each time we encounter a line starting with `Series Id:`. For all other lines, we simply append them (after a comma separator) to `combined`. Finally, we make sure to print the last running record before returning.

```bash
(iap-data-venv) ~/iap-class/assignments$ cat ../datasets/cleaning/labor.csv \
  | awk \
    '/^Series Id:/ {print combined; combined = $0}
    !/^Series Id:/ {combined = combined", "$0;}
    END {print combined}'
```

2. On  `crime-clean.txt`, the following command does a *fill* (first row of output: "Alabama, 2004, 4029.3"). 

   We first use `grep` to exclude the lines that only contain a comma. We then use `awk` to either extract the state (4th word) for lines starting with a capital letter (i.e. those starting with `Reported crime in ...`), or to print the state name followed by the data for lines that contain data.

```bash
(iap-data-venv) ~/iap-class/assignments$ cat ../datasets/cleaning/crime-clean.txt \
   | grep -v '^,$' \
   | awk \
   '/^[A-Z]/ {state = $4} 
    !/^[A-Z]/ {print state, $0}'
```
    
3. On `crime-clean.txt`, the following script converts the data to table format in CSV, where the columns are `[State, 2004, 2005, 2006, 2007, 2008]`. Note that it only works assuming perfectly homogenous data (i.e. no missing/extraneous values, years always in the same order). 

   We again begin by using `grep` to exclude the lines that only contain a comma. We then use `sed` to remove trailing commas, remove the phrase `Reported crime in `, and remove the year (first comma-separated field) from the data lines. Finally, using `awk`, we print the table header and then perform a *wrap* (see example 1 above).

```bash
(iap-data-venv) ~/iap-class/assignments$ cat ../datasets/cleaning/crime-clean.txt \
   | grep -v '^,$' \
   | sed 's/,$//g; s/Reported crime in //; s/[0-9]*,//' \
   | awk \
   'BEGIN {printf "State, 2004, 2005, 2006, 2007, 2008"} \
    /^[A-Z]/ {print c; c=$0}  
    !/^[A-Z]/ {c=c", "$0;}    
    END {print c}'
```

4. On `crime-unclean.txt` the following script performs the same cleaning as above, but allows incomplete information (*e.g.,* some years may be missing).

   We again begin by using `grep` to exclude the lines that only contain a comma. We then use `sed` to remove the phrase `Reported crime in `. Finally, using `awk`, we first split data lines into comma-separated fields (so that `$1` is the year and `$2` is the value); then, whenever we encounter such a line while parsing, we place the value into `array` using the year as an index; finally, whenever we encounter a line with text, we print the previous `state` and the associated `array`, delete `array`, and remember the state in the current line for future printing.

```bash
(iap-data-venv) ~/iap-class/assignments$ cat ../datasets/cleaning/crime-unclean.txt \
   | grep -v '^,$' \
   | sed 's/Reported crime in //;' \
   | awk -F',' \
     'BEGIN {
     printf "State, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008\n"}
     /^[A-Z]/ || /^$/ {
       if(state) {
         printf(state); 
         for(i = 2000; i <= 2008; i++) {
           if(array[i]) {
             printf("%s,", array[i])
           }
           else {
             printf("0,")
           }
         };
         printf("\n");
       } 
       state=$0; 
       delete array
     } 
     !/^[A-Z]/ {array[$1] = $2}'
```

We provided the last example to show how powerful `awk` can be. However if you need to write a long command like this, you may be better off using a proper scripting language, such as `python`!

### Part 1 Questions

*Hint: Look into `awk`'s `split` function, and `for loop` constructs (*e.g.,* [arrays in awk](http://www.math.utah.edu/docs/info/gawk_12.html)).

**Q1:** Starting with `worldcup-semiclean.txt`, write a script that uses the above tools as appropriate to generate output as follows and outputs it to `../datasets/cleaning/worldcup-clean.csv`, *i.e.,* each line in the output contains a country, a year, and the position of the county in that year (if within top 4):

```
BRA,1958,1
BRA,1962,1
BRA,1970,1
BRA,1994,1
BRA,2002,1
BRA,1950,2
BRA,1998,2
...
```

**Q2:** According to `worldcup-clean.csv`, how often has each country won the world cup? Write a script to compute this, by generating output as follows and outputting it to `../datasets/cleaning/worldcup-wins.csv`:

```
BRA,5
GER,4
ITA,4
...
```

[*Back to top*](#table-of-contents)

## Part 2: Missing value imputation 

In this part we will examine the impact of different data imputation approaches on the results of an analysis on `salaries.csv`. As is often the case when using user survey data, this dataset contains many missing values, which we must decide how to handle.

### Exploring the data

Let's launch a python shell, import the data and examine the resulting dataset:
```sh
(iap-data-venv) ~/iap-class/assignments$ python3
```
```python
>>> import pandas as pd
>>> data = pd.read_csv("../datasets/cleaning/salaries.csv", encoding = "ISO-8859-1")
>>> data
     salary_id           employer_name      location_name location_state location_country  ...  signing_bonus  annual_bonus stock_value_bonus                                           comments   submitted_at
0            1                  opower  san francisco, ca             CA               US  ...         5000.0           0.0       5000 shares                                   Don't work here.  3/21/16 12:58
1            3                 walmart    bentonville, ar             AR               US  ...            NaN        5000.0             3,000                                                NaN  3/21/16 12:58
2            4      vertical knowledge      cleveland, oh             OH               US  ...         5000.0        6000.0                 0                                                NaN  3/21/16 12:59
3            6                  netapp            waltham            NaN              NaN  ...         5000.0        8500.0                 0                                                NaN  3/21/16 13:00
4           12                   apple          cupertino            NaN              NaN  ...         5000.0        7000.0            150000                                                NaN  3/21/16 13:02
..         ...                     ...                ...            ...              ...  ...            ...           ...               ...                                                ...            ...
502       1093               microsoft        redmond, wa             WA               US  ...        30000.0       10000.0              8000                                                NaN  3/21/16 14:19
503       1094               (private)         boston, ma             MA               US  ...            0.0           0.0                 0  Retirement benefits very good... ~7% to ~14% (...  3/21/16 14:22
504       1097                 dropbox      san francisco            NaN              NaN  ...        25000.0           0.0             40000                                                NaN  3/21/16 14:19
505       1098  pricewaterhousecoopers          australia            NaN               AU  ...            0.0        2000.0                 0                                                NaN  3/21/16 14:20
506       1100                   apple          sunnyvale            NaN              NaN  ...        20000.0       10000.0            100000                                                NaN  3/21/16 14:20

[505 rows x 18 columns]
```

We can now examine the degree of prevalence of null values in the dataset:
```
>>> print(data.isnull().sum())
salary_id                      0
employer_name                  1
location_name                  0
location_state               307
location_country             253
location_latitude            253
location_longitude           253
job_title                      0
job_title_category             0
job_title_rank               362
total_experience_years        15
employer_experience_years      9
annual_base_pay                0
signing_bonus                 94
annual_bonus                  92
stock_value_bonus            112
comments                     419
submitted_at                   0
dtype: int64
```

As you can see, certain fields have been filled in by every user. Such fields include both information that was probably generated by the survey form itself (e.g. `salary_id`, `submitted_at`), as well as information that all users happened to consider essential to their responses (e.g. `location_name`, `job_title`). However, most fields contain at least a few null values. Interestingly, some of these fields we might also have considered essential (e.g. `employer_name`). 

### Part 2 Questions

**Q3:** The easiest way to deal with missing values is to simply exclude the incomplete records from our analysis. Two deletion approaches are most common: pairwise deletion, where we only exclude records that have missing values in the column(s) of interest, and listwise deletion, where we exclude all records that have at least one missing value. Use pairwise deletion to determine the mean and standard deviation of `annual_bonus` among the survey respondents. Then, use listwise deletion for the same task instead.

**Q4:** A slightly more sophisticated approach is to replace all missing values in a column with the same value (often the average of the existing values in the same column, or a special value like 0). Use these two approaches to determine the mean and standard deviation of `annual_bonus` among the survey respondents.

**Q5:** Imputing missing values with the same value preserves the number of data points, but can create skew in the dataset. One way to combat this issue is by instead determining each imputed value from other existing values for the same record. Based on all respondents that report a **non-zero** `annual_bonus`, calculate the average `annual_bonus`/`annual_base_pay` ratio. Then, assume any respondent that didn't include `annual_bonus` information will actually receive that same ratio of their `annual_base_pay` as an annual bonus. Use this approach to determine the mean and standard deviation of  `annual_bonus` among the survey respondents.

[*Back to top*](#table-of-contents)
