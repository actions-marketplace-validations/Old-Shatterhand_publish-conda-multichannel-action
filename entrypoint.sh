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
	platforms=$(echo $INPUT_PLATFORMS | tr "," "\n")
    
	# may be replaced by {'python': [$INPUT_VERSIONS]}
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
	
	build_command+=" --output-folder . --no-test "
	if [ -z $INPUT_FOLDER ]
	then
		build_command+="."
	else
		build_command+="$INPUT_FOLDER"
	fi
	
	echo "Execute command: $build_command"
	eval "$build_command"

	for platform in $platforms; do
		cp_cmd="conda convert -p $platform linux-64/*.tar.bz2"
		echo "Convert command: $cp_cmd"
		eval "$cp_cmd"
	done
	# conda convert -p osx-64 linux-64/*.tar.bz2
}

upload_package(){
	platforms=$(echo $INPUT_PLATFORMS | tr "," "\n")
	export ANACONDA_API_TOKEN=$INPUT_ANACONDATOKEN
	
	anaconda upload --label main linux-64/*.tar.bz2
	
	for platform in $platforms; do
		ul_cmd="anaconda upload --label main $platform/*.tar.bz2"
		echo "Upload command: $ul_cmd"
		eval "$cp_cmd"
	done
	# anaconda upload --label main osx-64/*.tar.bz2
}

go_to_build_dir
# check_if_meta_yaml_file_exists
build_package
upload_package
