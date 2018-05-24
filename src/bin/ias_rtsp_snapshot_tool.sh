#!/bin/bash

function debug
{
	>&2 echo "Json creds: " $json_credentials_file
	>&2 echo "Camera config: " $camera_config_file
	>&2 echo "Username: " $username
	>&2 echo "Hostname: " $hostname
	>&2 echo "Output dir: " $output_dir
	>&2 echo "scene_prefix: " $scene_prefix
	>&2 echo "camera_config_file_without_extension:" $camera_config_file_without_extension
	>&2 echo "run-time: " $run_time
	>&2 echo "scene-ratio: " $scene_ratio
}

function usage
{
	echo ""
	echo "-- Usage --"
	echo "    $0 credentials_file.json camera_config.json"

	echo ""
	echo "-- Description --"
	echo "    Connects to an RTSP stream, waits 5 seconds, and takes a still image."

	echo ""
	echo "-- Config Examples --"
	echo '    credentials:   {"username":"someuser","password":"somepass"}'
	echo '    camera config: { "hostname":"some.hostname.example.com", "output-dir":"/var/somepath", "scene-prefix":"img"} '

	echo ""
	echo "-- Mandatory config parameters --"
	echo "Credentials:"
	echo "    username"
	echo "    password"
	echo "Camera config:"
	echo "    hostname"

	echo ""
	echo "-- Optional config parameters --"
	echo "Camera config:"
	echo "    output-dir - defaults to /var/tmp/rtsp_snapshots"
	echo "    scene-prefix - defaults to img"
	echo "    run-time - amount of time to watch the camera (man vlc)"
	echo "    scene-ratio - how often to take the picture (man vlc)"
	echo ""
	echo "-- Requires --"
	echo "    cvlc (vlc-core on rpm systems(?))"
	echo "    x264"
	echo "    jq"
	echo ""
	echo "-- Debugging --"
	echo "    export debug_camera_snapshot=1"
}

json_credentials_file="$1"
camera_config_file="$2"

if [[ -z "$json_credentials_file" ]]
then
	>&2 echo "ERROR: You didn't specify a credentials file."
	usage
	exit 1
fi

if [[ -z "$camera_config_file" ]]
then
	>&2 echo "ERROR: You didn't specify a camera_config file."
	usage
	exit 1
fi

jq=jq

username=`$jq --raw-output '.username' "$json_credentials_file"`
password=`$jq --raw-output '.password' "$json_credentials_file"`
hostname=`$jq --raw-output '.hostname' "$camera_config_file"`

# Optional parameters:
scene_prefix=`$jq --raw-output '.scene-prefix' "$camera_config_file" 2>/dev/null`
run_time=`$jq --raw-output '.run-time' "$camera_config_file" 2>/dev/null`
scene_ratio=`$jq --raw-output '.scene-ratio' "$camera_config_file" 2>/dev/null`

camera_config_file_without_extension="${camera_config_file%.*}"
camera_config_file_without_extension="${camera_config_file_without_extension##*/}"

if [[ -z "$scene_prefix" ]]
then
	prefix_date=`date '+%Y-%m-%d-%H-%M-%S'`
	scene_prefix="$camera_config_file_without_extension--$prefix_date--snapshot"
fi

if [[ -z "$run_time" ]]
then
	run_time="10"
fi

if [[ -z "$scene_ratio" ]]
then
	scene_ratio="120"
fi

output_dir="$rtsp_shapshot_output_dir"

if [[ -z "$output_dir" ]]
then
	output_dir=`$jq --raw-output '.output-dir' "$camera_config_file" 2>/dev/null`

	if [[ "$output_dir" == "null" ]]
	then
		unset output_dir
	fi
fi

if [[ -z "$username" ]]
then
	>&2 echo "ERROR: username not specified in config"
	usage
	exit 1
fi

if [[ -z "$password" ]]
then
	>&2 echo "ERROR: password not specified in config"
	usage
	exit 1
fi

if [[ -z "$hostname" ]]
then
	>&2 echo "ERROR: hostname not specified in config."
	usage
	exit 1
fi


if [[ -z "$output_dir" ]]
then
	output_dir=/var/tmp/rtsp_screenshots
fi


if [[ ! -z "$debug_camera_snapshot" ]]
then
	debug
fi

mkdir -p "$output_dir"

cvlc rtsp://$username:$password@$hostname \
--video-filter=scene \
--scene-prefix="$scene_prefix" \
--scene-format=jpg \
--scene-path="$output_dir" \
--scene-replace \
--scene-ratio $scene_ratio \
--vout=dummy \
--run-time "$run_time" \
vlc://quit
