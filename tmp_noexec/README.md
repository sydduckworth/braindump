# Problem

Mounting `/tmp` with `noexec` aims to enhance security by making it impossible for a would-be attacker to execute malicious code in that directory. In theory that sounds good but in practice, not so much. For example, `pip` expects `/tmp` to be a sandbox (`1777` permission), and will fail to build packages when it cannot execute scripts there.


This is what happens when you try to execute a script with `noexec` enabled:

```
$ echo -e '#!/bin/bash\necho succeeded\n' > /tmp/nope.sh
$ chmod 755 /tmp/nope.sh
$ /tmp/nope.sh
-bash: /tmp/nope.sh: Permission denied
```

Mapping shared memory as executable also fails:

```
  × Getting requirements to build editable did not run successfully.
  │ exit code: 1
  ╰─> [66 lines of output]
      Traceback (most recent call last):
        File "/tmp/[...]/site-packages/numpy/_core/__init__.py", line 22, in <module>
          from . import multiarray
        File "/tmp/[...]/site-packages/numpy/_core/multiarray.py", line 11, in <module>
          from . import _multiarray_umath, overrides
      ImportError: /tmp/[...]/site-packages/numpy/_core/_multiarray_umath.cpython-312-x86_64-linux-gnu.so: failed to map segment from shared object
      
      The above exception was the direct cause of the following exception:
      # ...
```


# Solution

Set the `TMPDIR` environment variable to point elsewhere.

From https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap08.html

> 8.3 Other Environment Variables
>
> ...
>
> TMPDIR
>
>    This variable shall represent a pathname of a directory made available for programs that need a place to create temporary files.

See [tmp-noexec.sh](tmp-noexec.sh). When `/tmp` is mounted with the `noexec` flag this script creates a directory in `/dev/shm` (a memory file system), secures it for the current user with `0700` permissions, and configures `TMPDIR`.

```
$ source /path/to/tmp-noexec.sh
System TMPDIR is mounted with noexec... Redirecting to /dev/shm/user/tmp

$ echo $TMPDIR
/dev/shm/user/tmp

$ mktemp -d
/dev/shm/user/tmp/tmp.YaPGnrZc16

$ mktemp
/dev/shm/user/tmp/tmp.QIU2XqnyTi

$ ls -l $TMPDIR
total 0
-rw-------. 1 user user  0 Jul  2 18:28 tmp.QIU2XqnyTi
drwx------. 2 user user 40 Jul  2 18:28 tmp.YaPGnrZc16
```

To enable this at logon for all systems you can `source` this script in your `~/.bash_profile`:

```bash
if [ -f /path/to/tmp-noexec.sh ]; then
    source /path/to/tmp-noexec.sh
fi
```

To enable this at login for all systems, and change the default storage path for specific hosts:

```bash
if [ -f /path/to/tmp-noexec.sh ]; then
    case "$(hostname -s)" in
        mydataserver)
            alt_tmp="/local/disk/$(whoami)/tmp"
            ;;
        mylowramserver)
            alt_tmp="/var/tmp/$(whoami)/tmp"
            ;;
    esac

    source /path/to/tmp-noexec.sh
fi
```



