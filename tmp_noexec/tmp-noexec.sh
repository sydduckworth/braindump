# Is /tmp mounted with noexec?
if grep -E '.* /tmp .*noexec' /etc/mtab &>/dev/null; then
    alt_tmp="${alt_tmp:-/dev/shm/$(whoami)/tmp}"
    alt_tmp_mode=700

    echo "System TMPDIR is mounted with noexec... Redirecting to $alt_tmp"

    # Create a new temporary storage area
    if ! mkdir -p "$alt_tmp"; then
        echo "Unable to create directory: $alt_tmp" >&2
        return 1;
    fi

    # Configure permissions (default is user+rwx,group-,other-)
    if ! chmod $alt_tmp_mode "$alt_tmp"; then
        echo "Unable to secure directory: $alt_tmp" >&2
        return 1;
    fi

    # Make the new temporary storage area the default
    export TMPDIR="$alt_tmp"

    # Clean up
    unset alt_tmp
    unset alt_tmp_mode
fi

