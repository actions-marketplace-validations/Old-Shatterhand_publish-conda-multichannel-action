#!/bin/bash

set -ex
set -o pipefail

go_to_build_dir() {
    if [ ! -z $INPUT_SUBDIR ]; then
        cd $INPUT_SUBDIR
    fi
}

check_if_meta_yaml_file_exists() {
    if [ ! -f meta.yaml ]; then
        echo "meta.yaml must exist in the directory that is being packaged and published."
        exit 1
    fi
}

build_package(){
	channels=$(echo $INPUT_CHANNELS | tr "," "\n")
	versions=$(echo $INPUT_VERSIONS | tr "," "\n")
    
	build_command="conda-build --variants \"{'python': ["
	for version in $versions; do
		build_command+="'$version', "
	done
	build_command=${build_command::-2}
	build_command+="]}\""
	
	build_command+=" -c conda-forge -c bioconda"
	for channel in $channels; do
		build_command+=" -c $channel"
	done
	
	build_command+=" --output-folder . --no-test ."
	echo "Execute command: $build_command"
	eval "$build_command"
    
	conda convert -p osx-64 linux-64/*.tar.bz2
}

upload_package(){
    export ANACONDA_API_TOKEN=$INPUT_ANACONDATOKEN
    anaconda upload --label main linux-64/*.tar.bz2
    anaconda upload --label main osx-64/*.tar.bz2
}

go_to_build_dir
check_if_meta_yaml_file_exists
build_package
upload_package
