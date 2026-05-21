# Dotfiles

These are my dotfiles. I made a script to save and load them from this repository:

```shell
# Clone this repository (~/.dotfiles is a magic path)
$ git clone https://github.com/sophie-iren-katz/dotfiles.git ~/.dotfiles

# Save dotfiles from my local filesystem into this repository
#
# Do this after making a change
$ cd ~/.dotfiles
$ ./dotfiles.bash save
$ git add -A .
$ git commit -m "<message>"
$ git push

# Load dotfiles from this repository into my local filesystem
#
# Do this when setting up a new machine
$ cd ~/.dotfiles
$ ./dotfiles.bash load
```

## Crontab

`crontab.txt` holds the scheduled jobs for this machine (currently the hourly
`~/.claude/backup.sh` run). It's the source of truth — edit the file, then
install it with:

```shell
$ crontab ~/.dotfiles/crontab.txt

# Verify what's installed
$ crontab -l
```

To capture the currently-installed crontab back into the repo before editing:

```shell
$ crontab -l > ~/.dotfiles/crontab.txt
```
