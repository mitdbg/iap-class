# iap-class
Resources for the "Programming with Data" IAP class.

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



