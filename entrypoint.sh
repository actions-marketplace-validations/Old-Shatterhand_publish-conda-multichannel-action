#!/bin/bash

set -ex
set -o pipefail

build_package(){
	channels=$(echo $INPUT_CHANNELS | tr "," "\n")
	versions=$(echo $INPUT_VERSIONS | tr "," "\n")
	platforms=$(echo $INPUT_PLATFORMS | tr "," "\n")

	# may be replaced by {'python': [$INPUT_VERSIONS]}
	build_command="conda-build -q --variants \"{'python': ["
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

	# conda convert -p osx-64 linux-64/*.tar.bz2
	# conda convert -p osx-arm64 linux-64/*.tar.bz2

	for platform in $platforms; do
		cp_cmd="conda convert -p $platform linux-64/*.tar.bz2"
		echo "Convert command: $cp_cmd"
		eval "$cp_cmd"
	done
}

upload_package(){
	platforms=$(echo $INPUT_PLATFORMS | tr "," "\n")
	export ANACONDA_API_TOKEN=$INPUT_ANACONDATOKEN

	anaconda upload --label main linux-64/*.tar.bz2

	# anaconda upload --label main osx-64/*.tar.bz2
	# anaconda upload --label main osx-arm64/*.tar.bz2

	for platform in $platforms; do
		ul_cmd="anaconda upload --label main $platform/*.tar.bz2"
		echo "Upload command: $ul_cmd"
		eval "$cp_cmd"
	done
}

build_package
upload_package
