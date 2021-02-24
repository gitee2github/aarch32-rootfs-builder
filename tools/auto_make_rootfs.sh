#!/bin/bash

###env values###
work_dir=$(realpath $(realpath $(dirname $0))/../)
default_rpmlist=${work_dir}/conf/rpmlist
rpmlist_file=""
rootfs_dir=""

###whether to create rootfs flag
create_rootfs_flag=0
create_rootfs_only_flag=0

TEMP=`getopt -o f:h --long rpmlist-file:,create-rootfs,rootfs-dir:,help,create-rootfs-only \
     -n 'err' -- "$@"`
if [ $? != 0 ] ; then exit 1 ; fi
eval set -- "$TEMP"

while true ; do
    case "$1" in
        -h|--help)
            echo -e "Usage: $0 [options]\n\n\
Options:\n \
 -h, --help\t\tshow this help message and exit.\n \
 -f, --rpmlist-file\tspecify rpmlist to build.\n \
\t\t\tdefault is ${work_dir}/conf/rpmlist.\n \
 --create-rootfs\tauto create rootfs,\n \
 --create-rootfs-only\tauto create rootfs only,\n \
\t\t\tif not specify rootfs dir by --rootfs-dir,\n \
\t\t\tthen use default dir ${work_dir}/arm32_rootfs/root.\n \
 --rootfs-dir\t\tspecify rootfs-dir.\n"
            exit 0
            break
            ;;
        -f|--rpmlist-file)
            if [ -z $2 ]; then
                echo "err: please specify rpmlist file"
                exit 1
            elif [ ! -f $2 ]; then
                echo "err: rpmlist file $2 not exists."
                exit 1
            else
                echo "specify rpmlist file $2, only build pkgs in this file."
                rpmlist_file=$2
                shift 2
            fi
            ;;
        --create-rootfs)
            echo "create rootfs."
            create_rootfs_flag=1
            shift
            ;;
        --create-rootfs-only)
            echo "create rootfs only."
            create_rootfs_only_flag=1
            shift
            ;;
        --rootfs-dir)
            echo "specify rootfs dir as $2"
            rootfs_dir=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "$1 is not an available parameter."
            exit 1
            ;;
    esac
done

function build_pkgs()
{
    local rpmlist_file=$1

    ### run auto_build_pkgs.sh to build pkgs
    rm -f ${work_dir}/output/fail_pkgs
    for i in `cat $rpmlist_file`
    do
        if [ $i == "gcc_secure" ]; then
            continue
        fi
        sh -x ${work_dir}/tools/auto_build_pkgs.sh $i
        if [ $? -ne 0 ]; then
    	    echo $i >> ${work_dir}/output/fail_pkgs
        else
            echo $i >> ${work_dir}/output/succ_pkgs
        fi
    done
}

rm -f $default_rpmlist
grep -r name ${work_dir}/conf/aarch32_support_list.yaml |awk '{print $NF}' | tee $default_rpmlist
if [ $create_rootfs_only_flag -eq 0 ]; then
    ###need to build pkgs
    if [ -z $rpmlist_file ]; then
        rpmlist_file=$default_rpmlist
    fi
    
    build_pkgs $rpmlist_file
fi

### if all pkgs build succ, and --create-rootfs option has seted, then start build rootfs
if [ $create_rootfs_flag -eq 1 ] || [ $create_rootfs_only_flag -eq 1 ]; then
    if [ -f ${work_dir}/output/fail_pkgs ]; then
        echo "cannot create rootfs while ${work_dir}/output/fail_pkgs exists, \
please check if all pkgs have been build succ, and then remove this file."
        exit 1
    fi

    if [ -z $rootfs_dir ]; then
        rootfs_dir="${work_dir}/arm32_rootfs/root"
    fi
    if [ -d $rootfs_dir ]; then
        rm -rf $rootfs_dir $rootfs_dir/../arm32_repo
        mkdir -p $rootfs_dir
    fi
    mkdir -p $rootfs_dir/../arm32_repo

    ###create arm32_repo
    find ${work_dir}/output | grep rpm$ | grep -v src | xargs -i /usr/bin/cp {} $rootfs_dir/../arm32_repo
    createrepo $rootfs_dir/../arm32_repo
    cat << EOF > /etc/yum.repos.d/arm32_rootfs.repo
[arm32_rootfs]
name = arm32_rootfs
baseurl = file://$rootfs_dir/../arm32_repo
enabled = 1
gpgcheck = 0
EOF

    ###makecache
    yum makecache --repo arm32_rootfs
    if [ $? -ne 0 ]; then
        echo "yum makecache failed."
	exit -1
    fi

    ###build arm32 rootfs
    yum install -y t3-setup glibc ftp p7zip dropbear e2fsprogs btrfs-progs iptables --exclude=xz-libs --installroot=${work_dir}/arm32_rootfs/root --forcearch armv7hl --repo arm32_rootfs
    if [ $? -ne 0 ]; then
        echo "arm32 rootfs build failed."
	exit -1
    fi
fi
