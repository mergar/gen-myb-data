#!/bin/sh
DST_DIR="/tmp/check_mirror"

show_match()
{
	local a= b=
	local _list= _match=0

	while getopts "a:b:" opt; do
		case "${opt}" in
			a) a="${OPTARG}" ;;
			b) b="${OPTARG}" ;;
		esac
		shift $(($OPTIND - 1))
	done

	for i in ${a}; do
		_match=0
		for j in ${b}; do
#			echo "[$i][$j]"
			if [ "${i}" = "${j}" ]; then
				if [ -z "${_list}" ]; then
					_list="${i}"
				else
					_list="${_list} ${i}"
				fi
				break
			fi
		done
	done

	echo " ${_list}"
}


## MAIN
if [ ! -d ${DST_DIR} ]; then
	echo "no ${DST_DIR}"
	exit
fi

_res=$( find ${DST_DIR} -mindepth 1 -maxdepth 1 -type d -exec basename {} \; )

if [ -z "${_res}" ]; then
	echo "empty ${DST_DIR}"
	exit
fi

hosts=
hosts_cnt=0

for i in ${_res}; do
	if [ -z "${hosts}" ]; then
		hosts="${i}"
	else
		hosts="${hosts} ${i}"
	fi

	export host${hosts_cnt}="${i}"
	hosts_cnt=$(( hosts_cnt + 1 ))
done

echo "Found [${hosts_cnt}]: ${hosts}"

#echo $host0
#echo $host1

host0_dir=$( find ${DST_DIR}/zx/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;  | sort | xargs )
host1_dir=$( find ${DST_DIR}/a/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | xargs )

#echo "HOST $host0: ${host0_dir}"
#echo "HOST $host1: ${host1_dir}"

_work_dir=$( show_match -a "${host0_dir}" -b "${host1_dir}" )

if [ -z "${_work_dir}" ]; then
	echo "no shared dir"
	exit 0
fi

echo "workdir: ${_work_dir}"

for profile in ${_work_dir}; do

	[ ! -r "${DST_DIR}/${host0}/${profile}/bad.txt" -o ! -r "${DST_DIR}/${host1}/${profile}/bad.txt" ] && continue

	host0_bad=$( cat ${DST_DIR}/${host0}/${profile}/bad.txt | xargs )
	host1_bad=$( cat ${DST_DIR}/${host1}/${profile}/bad.txt | xargs )

	echo "P: ${profile}"

	bad_list=$( show_match -a "${host0_bad}" -b "${host1_bad}" )

	echo "${bad_list}" > "${DST_DIR}/${profile}.bad"
done

exit 0
