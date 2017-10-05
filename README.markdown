#host_railsapp

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with [host_railsapp]](#setup)
    * [What [host_railsapp] affects](#what-[host_railsapp]-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with [host_railsapp]](#beginning-with-[host_railsapp])
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##Overview

The LarkIT-host_railsapp module provides the glue to create a Ruby on Rails hosting environment using RVM and Nginx/Passenger. It is currently only tested on CentOS 6.5.

##Module Description

This module uses maestrodev/rvm to install and manage ruby versions, and will setup Passenger with Nginx by default. That represents the "base" config.
Once the base config is in place, you can create "applications" which are effectively a combination of a user account, and some "rails environments" `[development, staging, production]`
Each rails environment will be setup as a virtual host in nginx.

##Setup

###What [host_railsapp] affects

* Install RVM
* Use RVM to install `$main_ruby_version`
* Install Phusion Pasenger gem into `$main_ruby_version`
* Setup Nginx module (effectively compile Nginx) and set it up as a service
* Allow the creation of "applications" which have:
  * user account and application directory
  * Associated .ssh configuration (allowing ssh keys to be included in all applications or just certain ones) -- *NOT YET IMPLEMENTED*
  * $HOME/.gemrc to add `--no-ri --no-rdoc`
  * `rails_environment` directories, which represent virtual hosts that are created in nginx
  * In each `rails_environment` directory:
    * Create an applicationname-environment specific gemset in RVM
    * .rvmrc to specify ruby version and gemset
    * shared/config/database.yaml (which will eventually be fully populated with useful details)
    * shared/logs - application logs
    * shared/weblogs - web error log by default

###Setup Requirements

This module requires "maestrodev/rvm" which requires `pluginsync` to be enabled in the `[main]` section of puppet.conf.
	
###Beginning with [host_railsapp]	

The very most basic configuration is like this:

```puppet
include host_railsapp
```

If you want to create some applications, try:

```puppet
# Create basic rails application named "myapp1"
host_railsapp::application { 'myapp1': }

# Create rails application "myapp2" with specific user/group names.
host_railsapp::application { 'myapp2':
  username  => 'someotheruser',
  groupname => 'someothergroup',
}

# Create rails application "someotherapp", but only create development and test rails_env's
host_railsapp::application { 'someotherapp':
  rails_environments => ['development', 'test'].
}

```

There are many parameters that can be specified, and at this point, it would probably be best to look at the individual modules for clues. Eventually I hope this documentation will give more elaborate examples.


##Usage

While it is not required, we recommend having a hieradata file with the following type of structure to allow you to "separate code from data" as much as possible. Here are a few examples:

### Example 1: Simple Hiera Data (one app)

```yaml
---
host_railsapp::applications: 'myapp'
```

Declaration in site.pp (or nodes.pp or whatever):

```puppet
include host_railsapp
```

### Example 2: List of Apps in Hiera Data

```yaml
---
host_railsapp::applications:
    - 'myapp1'
    - 'myapp2'
    - 'myapp3'
```

Declaration in site.pp (or nodes.pp or whatever):

```puppet
include host_railsapp
```

### Example 3: List of applications, with special parameters for each

Here would be an example of how to re-create the [Beginning with [host_railsapp]](#beginning-with-[host_railsapp]) example with hieradata.

Example Hiera data:

```yaml
---
host_railsapp::applications:
    # Use empty hash '{}' to use default settings
    'myapp1': {}
    'myapp2': {
        'username': 'someotheruser',
        'groupname': 'someothergroup',
    }
    'someotherapp': {
        'rails_environments': ['development', 'test'],
    }
```

Declaration in site.pp (or nodes.pp or whatever):

```puppet
include host_railsapp
```

##Reference

* Classes
  * host_railsapp (init.pp)
* Types
  * host_railsapp::application
  * host_railsapp::rails_environment
  * host_railsapp::directory (internal)
  * host_railsapp::sshkeys (internal)

##Limitations

This is only tested on CentOS Linux 6.5 for now.

##Development

Fork me on GitHub, create a feature branch, make your changes, submit a pull request.

##Release Notes/Contributors/Etc

* 0.2.0 - Allow overrides of application parameters in hieradata (or in initial declaration)
* 0.1.0 - First release - basic functionality, still mostly using defaults
