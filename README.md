[![Gem Version](https://badge.fury.io/rb/megahal.svg)](http://badge.fury.io/rb/megahal)
[![Dependency Status](https://gemnasium.com/kranzky/megahal.png)](https://gemnasium.com/kranzky/megahal)
[![Codeship Status for jasonhutchens/megahal](https://codeship.com/projects/8f43e890-e5b4-0132-1716-266c7b4e6c8b/status?branch=master)](https://codeship.com/projects/82076)

Sesame
======

Sesame is a simple password manager for the command-line.

Creating a Cave
---------------

Your passwords are stored in a secure cave, guarded by a Jinn that will only
grant access if the correct magic words are uttered.

To get started, install Sesame and create a new cave. Note that the `--echo`
argument is used to display sensitive information such as the generated
passphrase; omit `--echo` it to have this copied to the clipboard instead.

```bash
$ gem install sesame
$ sesame --echo
╔═════════════════════════════════════╗
║ ┏━━━┓ ┏━━━┓ ┏━━━┓  ┏━┓  ┏┓ ┏┓ ┏━━━┓ ║
║ ┗━╋━┓ ┣━━┫  ┗━╋━┓ ┏┻━┻┓ ┃┗┳┛┃ ┣━━┫  ║
║ ┗━━━┛ ┗━━━┛ ┗━━━┛ ┗   ┛ ┗   ┛ ┗━━━┛ ║
╚═════════════════════════════════════╝

🧞  - "Your new cave is ready, master. Please commit these magic words to memory..."
mammal glue wage paper store detail weave date

🧞  - "What is your command?"
1. list
2. add
3. get
4. next
5. delete
6. exit
7. help

> exit
🧞  - "I have secured your treasure with this key..."
sky tea ant ice
```

You will notice that Sesame enters interactive mode, allowing you to issue
multiple commands in a single session. When you exit from interactive mode, the
cave will be locked with a short phrase.

Remembering the Passphrase
--------------------------

By default, Sesame generates an eight-word passphrase that is used to secure
your cave. Try to remember it in groups of two or three consecutive words, and
associate those words with something you know well (such as walking through your
home, from the front door to the bathroom).

If you must write the passphrase down, please make sure to store the paper that
you write it on securely (ideally in a safe).

Unlocking the Cave
------------------

Upon exiting interactive mode for the first time, Sesame will lock your cave
with a short code. In the example above, that code is `sky tea ant ice`. The
next time you run Sesame, you will be prompted to enter the short code instead
of your eight-word passphrase.

Instead of entering the full code, you may also enter just the first letter of
each word. For the example above, entering `stai` as the unlock code will also
work.

Keeping your cave locked this way is convenient, but anyone with access to your
computer would be able to crack the lock with a small amount of effort. It is
therefore recommended to expunge the lock when you don't need it. You can do
this with the `--expunge` argument.

Adding a Service
----------------

You can add, list, retrieve and delete passwords for different services. 

```bash
> add twitter kranzky
🧞  - "Your new magic words are..."
nylon sand slice party
```

Listing Services
----------------

```bash
> list
🧞  - "Behold! Tremble in awe at the greatness of these heroes!"
twitter
facebook
google (2)
```

If several user accounts exist for the same service, a number will be displayed
in brackets. View all accounts by listing the service.

```bash
> list google
🧞  - "Behold! Tremble in awe at the greatness of these heroes!"
lloyd@kranzky.com
pazu@kranzky.com
```

Retrieving a Password
---------------------

You can retrieve a password for an existing service. You only need to specify
the name of the user account if more than one exists for the service.

```bash
> get google lloyd@kranzky.com
🧞  - "Master, the magic words for lloyd@kranzky.com of google are..."
rainy area rough feather
```

Updating a Password
-------------------

From time-to-time you may wish to update the password that you use for a
particular service. The `next` command allows you to do that.

```bash
> next google lloyd@kranzky.com
```

Removing a Service
------------------

You can delete services from your cave.

```
> delete google pazu@kranzky.com
```

Recovering a Lost Cave
----------------------

Sesame stores your cave in an encrypted file named `sesame.cave`. You should
keep this file in Dropbox or iCloud or a similar service to ensure that you
don't lose it. However, if the worst happens and you do lose that file, you may
recover it by specifying the `--reconstruct` argument when creating a new cave.

You will be prompted to enter the passphrase that you wish to use. As long as
you use the same passphrase as the one you used for your lost cave, the
passwords generated for the services you add to the cave will be the same.

Command-line Options
--------------------

Run with the `--help` argument to view all options.

You can issue commands directly, which will suppress interactive mode.

```
$ sesame -qegs twitter
Enter unlock code.
🔑  ****
Opened ./sesame.cave
Password for twitter / kranzky:
nylon sand slice party
```

Configuration
-------------

TBD

Contributing
------------

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright (c) 2018 Jason Hutchens and Jack Casey. See UNLICENSE for further details.
