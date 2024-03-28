#! /bin/bash

rmt_host="192.168.1.31"
rmt_user="ant"
rmt_port=22
rmt_basedir="/home/ant/target/rootfs"
sshpass_passwd="your_password"

file_list="
	/usr/include/xxx.h
	/usr/local/lib/libxxx.so
	/usr/local/sbin/dispatcher.sh
	/root/.ssh/authorized_keys
	/etc/config/xxx.conf
	/no/such/file.txt
"

scp2rmt() {
	local file_path="$1"
	local new_dir=`dirname $file_path`

	echo "MKDIR> ${new_dir}"
	$DO sshpass -p "$sshpass_passwd" \
		ssh -p ${rmt_port} ${rmt_user}@${rmt_host} "mkdir -p ${rmt_basedir}/${new_dir}"

	echo "SCP>   $file_path -> ${rmt_host}"
	$DO sshpass -p "$sshpass_passwd" \
		scp $file_path ${rmt_user}@${rmt_host}:${rmt_basedir}/${new_dir}

}

init_chk() {
	if ! command -v sshpass > /dev/null 2>&1; then
		echo "Please install sshpass"
		exit 1
	fi
}

do_main() {
	init_chk
	for f in $file_list; do
		if [ -f "$f" ]; then
			scp2rmt "$f"
		else
			echo "ERRO>  NO such file: $f" 
		fi
	done
	echo "DONE :)"
}

do_main
