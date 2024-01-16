# iap-class
Welcome to the "Programming with Data" IAP class!

## Getting Started
You can clone this repository to your local machine by executing the following at a terminal
```
$ git clone git@github.com:mitdbg/iap-class.git
$ cd iap-class
```
To finish your installation, please look at the "Setup" section below.

## Logistics

We will have a total of 8 lectures on the following topics:
1. **Processing**: The relational data model and SQL.
2. **Pandas and Data Wrangling**: Using the relational model in Python; working with text data.
3. **Preparation**: Data preparation and cleaning.
4. **Presentation**: Data visualizations and plotting.
5. **Prediction**: Introduction to some Machine Learning techniques
6. **PyTorch**: Introduction to Neural Networks.
7. **Performance**: Improving data processing performance.
8. **Parallelism**: Further improving performance through parallelism.

We will also have optional assignments each day: a shorter one over lunch and a longer one overnight. You are free to do these at your own pace, or not at all; they are just meant to give you some practiec with the techniques.

The schedule for each day will be as folllows:
- **10:00-10:15**: Homework questions from day before
- **10:15-11:45**: Morning lecture
- **11:45-12:30**: Lunch and lunch assignment
- **12:30-14:00**: Afternoon lecture


## Setup

### Cloning this repository

You can use the following command to clone this repository locally:

``` 
git clone git@github.com:mitdbg/iap-class.git
```

If this is your first time cloning a repository from GitHub using SSH, you may want to read [the documentation](https://docs.github.com/en/get-started/getting-started-with-git/about-remote-repositories#cloning-with-ssh-urls) about how to set this up.


### Installing prerequisites

In order to complete the assignments included under `assignments/`, you will need to install some prerequisites and create a Python virtual environment. You can do this by running the following commands:

``` 
chmod +x setup.sh
sudo ./setup.sh
```

### Managing the virtual python environment

To avoid interfering with the versions of python packages you may have already installed on your machine, the setup script has installed all dependencies in a virtual environment called `iap-data-venv`. Whenever you use python in one of the assignments, make sure that you have activated this virtual environment by running:

```
source iap-data-venv/bin/activate
```

Once you are done, you can deactivate the virtual environment by running:

```
deactivate
```



