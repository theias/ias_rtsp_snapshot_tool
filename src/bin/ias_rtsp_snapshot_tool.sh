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
	echo '    camera config: { "hostname":"some.hostname.example.com", "output_dir":"/var/somepath", "scene-prefix":"img"} '

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
	echo "    output_dir - defaults to /var/tmp/rtsp_snapshots"
	echo "    scene-prefix - defaults to img"
	echo ""
	echo "-- Requires --"
	echo "    cvlc (vlc-core on rpm systems(?))"
	echo "    x264"
	echo "    jq"
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

scene_prefix=`$jq --raw-output '.scene-prefix' "$camera_config_file" 2>/dev/null`

camera_config_file_without_extension="${camera_config_file%.*}"
camera_config_file_without_extension="${camera_config_file_without_extension##*/}"

if [[ -z "$scene_prefix" ]]
then
	prefix_date=`date '+%Y-%m-%d-%H-%M-%S'`
	scene_prefix="$camera_config_file_without_extension--$prefix_date--snapshot"
fi

output_dir="$rtsp_shapshot_output_dir"

if [[ -z "$output_dir" ]]
then
	output_dir=`$jq --raw-output '.output_dir' "$camera_config_file" 2>/dev/null`

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
--scene-ratio 120 \
--vout=dummy \
--run-time 10 \
vlc://quit
