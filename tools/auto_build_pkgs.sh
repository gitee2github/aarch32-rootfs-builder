#!/bin/sh
set -e

###error number###
ERROR_NOT_FOUND_PKGS="101"

###env values###
work_dir=$(realpath $(realpath $(dirname $0))/../)
tools_dir=$work_dir/tools
patches_dir=$work_dir/patches
config_file=$work_dir/conf/aarch32_support_list.yaml
mock_repo_file="/etc/mock/templates/fedora-29.tpl"
output_dir=output
local_repo_dir=$work_dir/$output_dir/repo
download_prefix="https://repo.openeuler.org/openEuler-20.03-LTS/source/Packages"
download_suffix=".oe1.src.rpm"
oe_src_dir="oe_src_dir"

###build function###
build_pkg()
{

    local pkg_name=$1
    cat $config_file | grep -i '^- name:' | awk '{print $3}' | grep -w -i $pkg_name > /dev/null || exit $ERROR_NOT_FOUND_PKGS

    local pkg_version=$(cat $config_file | grep  "^- name: $pkg_name"  -A3 | grep revision | awk '{print $2}')
    local rpm_name=$pkg_name-$pkg_version$download_suffix
    mkdir -p ./$output_dir/$pkg_name
    pushd ./$output_dir/$pkg_name
    if [ ! -d $oe_src_dir ] ;
    then
        mkdir $oe_src_dir
    fi

    ###download oe src rpm###
    if [ ! -f $oe_src_dir/$rpm_name ];then
        wget $download_prefix/$rpm_name -P $oe_src_dir
    fi
    
    if [ ! -f $oe_src_dir $pkg_name.spec ];
    then
        ###get old spec###
        rpm2cpio $oe_src_dir/$rpm_name | cpio -idm  -D $oe_src_dir $pkg_name.spec
    
        ###patching spec###
        patch -d $oe_src_dir/ < $(ls $patches_dir/$pkg_name/spec/*.patch | sort -u)
    fi
    ###starting build###
    mock -r fedora-29-armhfp  --resultdir=. ./$oe_src_dir/$rpm_name --spec oe_src_dir/$pkg_name.spec --nocheck --macro-file=$tools_dir/rpmmacros_openeuler  --no-cleanup-after
    popd
}

repo_sync()
{
    local list=$1
    local create_flag=0
    local repo_flag=$(cat $mock_repo_file | grep  '^\[arm32_extra_repo\]')
    if [ ! -n "$repo_flag" ];
    then 
        sed -i '$i\[arm32_extra_repo]' $mock_repo_file
        sed -i "\$i\baseurl=file:\/\/$local_repo_dir" $mock_repo_file
        sed -i '$i\gpgcheck=0' $mock_repo_file
        sed -i '$i\enabled=1' $mock_repo_file
        sed -i '$i\skip_if_unavailable=False' $mock_repo_file
        mkdir -p $local_repo_dir
    fi
    for pkg in $list;
    do
        if [ -n "$(find $local_repo_dir | grep -i -w $pkg)" ];
        then
            continue
        fi
        find $work_dir/$output_dir/$pkg -maxdepth 1 -name '*.rpm' | xargs -I {} cp {} $local_repo_dir
        create_flag=1
    done
    if [ $create_flag == 1 ];
    then
        createrepo $local_repo_dir
    fi
}



pre_pkg_list=""

if [ $1 != "glibc" ];
then
    build_pkg $1
else
    pre_pkg_list="gcc_secure"
    for pkg in $pre_pkg_list
    do
        build_pkg $pkg
    done

    repo_sync $pre_pkg_list
    build_pkg $1
fi

