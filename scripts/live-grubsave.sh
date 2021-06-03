#!/bin/bash

# live-grubsave - script to save certain bootparameter into grubenv


grubsave() {

    local pcl par p
    local par=(  # boot parameter to save (as par=value pair)
        lang
        kbd
        kbvar
        kbopt
        tz
        from
        hwclock
        splasht
        blab  blabel bootlabel
        bdev  bootdev
        bdir  bootdir
        buuid bootuuid
        plab  plabel persistlabel
        pdev  persistdev
        puuid persistuuid
        pdir  persistdir
        live_swap
        automount
        kernel
        )
    local flg=(  # boot parameter as flags 
        toram
        disable_theme
        disable_background
        dostore
        nostore
        norepo
        )
    local per=(  # boot persistence parameter
        persist_all
        persist_root
        persist_static
        p_static_root
        persist_home
        frugal_persist
        frugal_root
        frugal_static
        f_static_root
        frugal_home
        frugal_only
    )
    local -A FLG  # hash of to be saved flag-parameter
    local -A PAR  # hash of to be saved parameter (with par=value)
    local -A PER  # hash of to be saved persistence parameter
    local -A GRP  # hash of found parameter

    for p in "${flg[@]}"; do FLG["$p"]="true"; done
    for p in "${par[@]}"; do PAR["$p"]="$p"; done
    for p in "${per[@]}"; do PER["$p"]="$p"; done

    local is_mp=true  # no toram
    for c in $(cat /proc/cmdline); do
        p="${c%%=*}"
        if [ -n "${FLG[$p]}" ]; then
           GRP[$p]="${FLG[$p]}"
        fi
        if [ -n "${PAR[$p]}" ]; then
           #echo GRP[$p]="${c##*=}"
           GRP[$p]="${c##*=}"
        fi
        if [ -n "${PER[$p]}" ]; then
            #echo GRP[persistence]="${p}"
            GRP[persistence]="${p}"
        fi
    done

    local config=/etc/live/config/initrd.out
    local BOOT_DEV  BOOT_FSTYPE BOOT_MP BOOT_UUID
    if [ -f $config ]; then
        eval "$(grep -E '^BOOT_(DEV|FSTYPE|MP|UUID)=' $config)"
    fi
    [ -z "$BOOT_MP" ] && return 1 # no live mount point found

    if ! mountpoint -q $BOOT_MP; then # seem toram was used
        is_mp=false
        mount -t $BOOT_FSTYPE UUID=$BOOT_UUID $BOOT_MP || return 1
    fi
    local grub_config="/boot/grub/config"
    local grub_env="/boot/grub/grubenv.cfg"

    [ -e $BOOT_MP$grub_config ] || return 1  # no grub-confg live-system
    grub_env="${BOOT_MP}${grub_env}"
    local grub_head=""

    read grub_head <<EOF
#GRUB parameter saved by live-grubsave on live system
#
EOF

    if (( ${#GRP[@]} >= 1 )) && touch ${grub_env} 2>/dev/null ; then
        echo "$grub_head" > ${grub_env}
        for p in $( printf "%s\n" ${!GRP[@]} | sort ) ; do
            echo $p='"'"${GRP[$p]}"'"' >> ${grub_env}
        done
    fi
    echo ${grub_env}
    cat ${grub_env}
    sync; sync
    if [ "$is_mp" = "false" ]; then
        mountpoint -q $BOOT_MP && umount $BOOT_MP
    fi
}

grubsave

exit $?

