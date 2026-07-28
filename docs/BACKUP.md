# Backups

Three layers, because "my laptop broke" is three different problems wearing one
coat:

| Layer | Covers | Restore takes |
| --- | --- | --- |
| This repository | Every dotfile, tool and shell config | minutes — `chezmoi init --apply` |
| `restic` snapshots | `$HOME`: code, keys, notes, browser profiles | minutes for one file, ~1 h for everything |
| Disk image | The whole partition, bootloader included | ~30 min, and it is the only one that needs no reinstall |

The first already existed. The other two are what this document is about.

## Two facts about the host that shape all of this

**Check what `/` actually lives on before trusting any of the defaults here:**

```sh
lsblk -o NAME,SIZE,TRAN,FSTYPE,MOUNTPOINT
```

Two answers change the design. If `TRAN` says `usb`, root is on an external
enclosure — a loose cable or a dead bridge chip takes the system offline in a
way an internal drive rarely does, which raises the value of an off-machine copy
(§3) considerably. And if `FSTYPE` is plain ext4 with no LVM or btrfs beneath
it, there is **no atomic snapshot**, so a consistent whole-disk image can only
be taken with the filesystem unmounted (§5).

## 1. What is backed up

`$HOME`, minus `~/.config/restic/excludes`. In practice that removes the large
majority of the bytes — on a working developer home, media and regenerable
caches routinely account for **~98% of the total**, leaving a snapshot in the
low single-digit gigabytes.

That ratio is the entire design, not a space optimisation. A backup measured in
gigabytes runs every night and gets verified; one measured in hundreds of
gigabytes gets postponed until the disk dies.

What is excluded, and why it is safe to exclude:

| Excluded | Typical share of `$HOME` | Rebuilt by |
| --- | --- | --- |
| media directories | the bulk of it | not the machine's state |
| `~/.cache`, `~/.npm`, `~/.bun`, mise, rustup | ~10% | `mise install`, `bun install` |
| `node_modules`, `.venv`, `.next`, `.terraform` | a few % | one install command |
| anything tagged `CACHEDIR.TAG` (cargo `target/`, …) | varies | the build |

Check your own split before trusting those proportions:

```sh
du -sh ~/* ~/.[a-z]* 2>/dev/null | sort -rh | head -20
```

`~/.config/restic/excludes` covers what is true of any developer machine. What
is true only of *this* one — a media library, a scratch mount, a client's tree —
goes in a file beside it that is **not** managed and **not** committed:

```sh
# ~/.config/restic/excludes.local
/home/you/some-media-library
```

Same reasoning as `env.local` in §3 (decision #30): this repository is public,
and a list of paths is a description of the machine. `dotfiles backup` passes it
as a second `--exclude-file` whenever it exists, and does nothing special when
it does not.

> Create this **before** the first backup on a machine with a large media
> directory. Otherwise the first run cheerfully snapshots all of it.

Everything else goes in — including `.git` directories, SSH keys, browser
profiles and `~/.claude`. When in doubt the file is kept; the exclude list names
only things with a command that regenerates them.

Alongside it, `dotfiles backup` refreshes a **rebuild manifest** into
`~/.local/state/dotfiles/system/`: `dpkg` selections, manually-installed
packages, the mise tool list, partition geometry, `/etc/fstab`, a `/etc`
tarball, and a dump of every **Docker volume**. That directory is inside
`$HOME`, so it rides along in the same snapshot with no separate job to forget
about.

Docker volumes are worth calling out. They live under `/var/lib/docker/volumes`
— outside `$HOME`, so nothing else here would catch them — and they are the one
place on this machine holding state that no command regenerates. They are
dumped through a throwaway container rather than read off disk, so the whole
backup stays unprivileged: no sudo, no root timer.

Two caveats. The dump is taken **live**, so a database mid-write can produce a
torn tar — stop the container first for any volume you would restore from rather
than rebuild. And the helper image is whichever of `alpine`/`busybox` is already
present locally; the job never pulls, because a nightly backup must not fail on
an unreachable registry.

What is deliberately *not* covered: Docker images and build cache. Both grow
without bound on a machine that builds regularly — hundreds of gigabytes is
ordinary — and every byte is a re-pull or a rebuild away. Worth auditing
occasionally rather than backing up:

```sh
docker system df          # build cache in particular is often mostly reclaimable
docker builder prune      # nothing active is ever removed
```

## 2. First run

```sh
dotfiles backup init      # creates the repository, prints the encryption key
dotfiles backup           # first snapshot — the slow one
```

`init` prints a randomly generated key **once**. Put it in Bitwarden, or on
paper in a drawer.

> Losing the key loses every snapshot. restic keeps no escrow copy and there is
> no reset. A key stored only on the machine it protects is not a key.

After that the systemd user timer runs it nightly, catching up on the next boot
if the laptop was asleep:

```sh
systemctl --user status dotfiles-backup.timer
```

If you mostly reach this machine over SSH rather than logging in, user timers
only run while a session exists — `sudo loginctl enable-linger $(id -un)` fixes
that.

## 3. Getting it off this machine

**The repository defaults to `/var/backups/restic`, which is on the disk it is
protecting.** That is real protection against deleting the wrong directory, and
no protection at all against the disk itself failing. `dotfiles doctor` says so
every time you run it, and will keep saying it until this section is done.

Fixing it is one line, in a file that is **not** in this repository:

```sh
# ~/.config/restic/env.local     — not managed, not committed
RESTIC_REPOSITORY="sftp:backup-box:/srv/restic"
```

That file is untracked for the same reason `~/.ssh/config.d` is (decision #30):
the line names a host, and a hostname in a public repo is a map of the estate.
`~/.config/restic/env` sources it first, so it wins over every default — and
because the systemd unit reads the same file, the nightly run and the manual one
cannot drift apart.

Three targets that need no extra tooling:

```sh
RESTIC_REPOSITORY="sftp:user@host:/srv/restic"          # any box with SSH
RESTIC_REPOSITORY="b2:bucket-name:laptop"               # cents/month at this size
RESTIC_REPOSITORY="/media/$USER/BACKUP/restic"          # external USB disk
```

For B2 or S3 the credentials go in the same `env.local`, as
`B2_ACCOUNT_ID` / `B2_ACCOUNT_KEY`. For an external disk, the backup simply
fails on the nights it is unplugged, which is the correct behaviour.

### Keep both: local for speed, remote for disaster

Rather than moving the repository off-machine, set a **mirror** and keep both:

```sh
# ~/.config/restic/env.local
BACKUP_MIRROR_REPOSITORY="rclone:gdrive:restic"
```

Every run backs up locally first, then copies the new snapshots onward. They
fail differently, which is the point — the local repository restores a deleted
file in seconds with no network, and the remote one is what still exists after
the laptop is stolen. `restic copy` transfers only what the destination lacks,
so the nightly cost is the day's changes rather than the whole repository.

If the mirror is unreachable the local snapshot is already written and the run
still succeeds; `dotfiles doctor` reports the mirror separately and fails if it
is configured but empty.

### Google Drive

restic has no Drive backend — `rclone` bridges it. Configure the remote once:

```sh
rclone config
#  n) new remote   →  name it `gdrive`   →  storage: drive
#  scope: 1 (full access)   →  leave the client id/secret blank for now
#  y) use auto config  →  a browser opens for the Google login
rclone lsd gdrive:            # confirm it works
```

Then point the mirror at it and initialise:

```sh
# ~/.config/restic/env.local
BACKUP_MIRROR_REPOSITORY="rclone:gdrive:restic"
```

```sh
dotfiles backup init          # creates the mirror with the same key
dotfiles backup               # first copy — the slow one
```

Three things about Drive specifically, learned the hard way by many people:

- **Make your own OAuth client ID.** rclone ships a shared one that every user
  on earth is hammering, and Google throttles it hard — the difference is
  routinely 10× on upload. `rclone config` → the remote → `client_id`. rclone's
  own documentation walks through creating one in Google Cloud Console.
- **Watch the quota.** The free tier is 15 GB shared across Gmail, Photos and
  Drive. This repository is small, but it grows with your history.
- **Drive dislikes many small files**, which is exactly restic's access
  pattern. It works, and it is slower than object storage. If it frustrates
  you, Backblaze B2 is a drop-in `RESTIC_REPOSITORY`/mirror change and costs
  cents per month at this size.

The Drive copy is encrypted before it leaves the machine. Google stores opaque
packs and never sees a filename.

## 4. Restoring

**One file, the common case.** Browse the history as a filesystem and copy out
of it:

```sh
dotfiles backup mount          # ~/restic-mount, ctrl-c to unmount
```

Snapshots appear under `snapshots/latest/`, and every previous version beside
it. This is almost always what you want.

**A whole tree.** Unpacks into a timestamped staging directory, never over your
live home directory:

```sh
dotfiles backup list                    # pick a snapshot id
dotfiles backup restore <snapshot-id>   # -> ~/restore-20260728-143000/
```

Restoring in place is available, spelled out, and asks before it acts:

```sh
dotfiles backup restore --in-place <snapshot-id>
```

**A whole machine, from nothing.** Install Debian, then:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Satcomx00-x00/dotfiles/main/install.sh)"
# restore the restic key to ~/.config/restic/password first, then:
dotfiles backup restore <snapshot-id>
```

Package layer, if you want the exact set back:

```sh
sudo dpkg --set-selections < ~/.local/state/dotfiles/system/dpkg-selections.txt
sudo apt-get dselect-upgrade
```

**A Docker volume.** The dumps are plain uncompressed tars, one per volume,
beside a `.json` of the volume's metadata:

```sh
cd ~/.local/state/dotfiles/system/docker-volumes
docker volume create my-postgres-data
docker run --rm -i -v my-postgres-data:/vol alpine tar -xf - -C /vol < my-postgres-data.tar
```

## 5. Bare metal: the disk image and `/etc`

The snapshot is data. The image is the machine — bootloader, partition table,
`/etc`, everything — and it is the difference between a one-hour rebuild and a
thirty-minute restore.

**It has to be taken offline.** ext4 with no LVM or btrfs underneath has no
atomic snapshot, so imaging a mounted root filesystem produces a copy that is
internally inconsistent in ways that only surface when you try to boot it.

With [Clonezilla](https://clonezilla.org/) on a USB stick:

1. Boot the stick, choose `device-image`, then `savedisk`.
2. Pick the disk holding `/`, confirmed against `lsblk` beforehand. On a
   dual-boot machine the other one is an OS you did not mean to overwrite.
3. Target an external disk with room for the *used* blocks. Clonezilla skips
   free space but not large media directories, so keeping those on a separate
   disk shrinks the image dramatically. Check the figure with `df -h /`.
4. Keep two images and overwrite the older.

Worth doing after anything you would hate to redo — a kernel or Debian release
upgrade, a partition change, a working driver fix — rather than on a schedule.
Between images, the nightly restic snapshot is what is actually protecting you.

`/etc` is captured automatically into the manifest whenever `sudo` runs without
a prompt; where it would prompt, the step is skipped and says so rather than
stalling a nightly job. `shadow` and `gshadow` are
deliberately skipped — password hashes do not belong in a home directory, and a
rebuild sets a new password anyway.

## 6. Checking it still works

An unverified backup is a hope. `dotfiles doctor` reports the age of the last
**successful** run, not merely whether the timer is enabled — a timer firing
nightly into a failing command looks healthy from every other angle:

```sh
dotfiles doctor
```

Monthly, verify the repository can actually be read back:

```sh
dotfiles backup check     # structure, plus a re-read of 5% of the data
```

And once, properly: restore a directory you know well into a staging path and
diff it. The first real test of a backup should not be the day you need it.

## When it goes wrong

| Symptom | Cause |
| --- | --- |
| `repository is already locked` | a previous run died. `restic unlock`. |
| Timer enabled, no snapshots | no session — `loginctl enable-linger` (§2) |
| `restic: command not found` from the timer | mise shim not on the unit's `PATH`; it is set explicitly in the service file |
| Backup grew enormously | a new build directory with no `CACHEDIR.TAG` — add it to `excludes` |
| `wrong password` | `env.local` points at a different repository than the key |
