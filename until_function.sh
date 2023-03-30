#!/bin/sh

#下载Adblock规则
function download_link(){
local IFS=$'\n'

target_dir="${1}"
test "${target_dir}" = "" && target_dir="${0%/*}/temple/download_Rules"
mkdir -p "${target_dir}"

list='
https://easylist-downloads.adblockplus.org/antiadblockfilters.txt|antiadblockfilters.txt
https://easylist-downloads.adblockplus.org/easylist.txt|easylist.txt
https://easylist-downloads.adblockplus.org/easylistchina.txt|easylistchina.txt
https://filters.adtidy.org/android/filters/15_optimized.txt|adguard_optimized.txt
https://filters.adtidy.org/extension/ublock/filters/224.txt|Adguard_Chinese.txt
https://filters.adtidy.org/extension/ublock/filters/11.txt|Adguard_mobile.txt
'
cd "${target_dir}"
for i in ${list}
do
test "$(echo "${i}" | grep -E '^#' )" && continue
	name=`echo "${i}" | cut -d '|' -f2`
		URL=`echo "${i}" | cut -d '|' -f1`
	test ! -f "${name}" && curl -k -L -o "${name}" "${URL}" >/dev/null 2>&1 && echo "※ `date +'%F %T'` ${name} 下载成功！"
dos2unix "${name}" >/dev/null 2>&1
done
}

#写入基本信息
function write_head(){
local file="${1}"
local count=`cat "${file}" | sed '/^!/d;/^[[:space:]]*$/d' | wc -l ` 
local original_file=`cat "${file}"`
cat << key > "${file}"
[Adblock Plus 2.0]
! Title: ${2}
! Version: `date +'%Y%m%d%H%M%S'`
! Expires: 12 hours (update frequency)
! Last modified: `date +'%F %T'`
! Total Count: ${count}
! Homepage: https://lingeringsound.github.io/adblock_auto
! Gitlink Homepage: https://www.gitlink.org.cn/keytoolazy/adblock_auto/tree/main/README.md
! GitHub Homepage: https://github.com/lingeringsound/adblock_auto
! GItlink Raw Link: https://code.gitlink.org.cn/api/v1/repos/keytoolazy/adblock_auto/raw/${file##*/}
! Github Raw Link: https://lingeringsound.github.io/adblock_auto/${file##*/}
key
echo "${original_file}" >> "${file}"
perl "${0%/*}/addchecksum.pl" "${file}"
}

#净化规则
function modtify_adblock_original_file() {
	local file="${1}"
	local new=`cat "${file}" | iconv -t 'utf8' | grep -Ev '^#\@\?#|^\$\@\$|^#\%#|^#\@\%#|^#\@\$\?#|^#\$\?#|^<<|<<1023<<' | sed 's|^[[:space:]]@@|@@|g' | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d;/^\[.*\]$/d' `
	echo "$new" > "${file}"
}

function make_white_rules(){
local file="${1}"
local IFS=$'\n'
local list=`cat "${0%/*}/white_list/white_list.prop" | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d' `
for i in ${list}
do
	sed -i "/${i}/d" "${file}"
done
}

function Combine_adblock_original_file(){
local file="${1}"
local target_folder="${2}"
test "${target_folder}" = "" && echo "※`date +'%F %T'` 请指定合并目录……" && exit
for i in "${target_folder}"/*.txt
do
	dos2unix "${i}"
	echo "`cat "${i}"`" >> "${file}"
done
}

#筛选整理规则
function wipe_white_list() {
	local file="${2}"
	local output_folder="${1}"
	if test -f "${file}" ;then
		rm -f "${output_folder}/${file##*/}"
	local new=$(cat "${file}" | grep -Ev "${3}" | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d' )
		mkdir -p "${output_folder}"
			cd "${output_folder}"
		echo "$new" > "${file##*/}"
	fi
}

function sort_web_rules() {
	local file="${2}"
	local output_folder="${1}"
	if test -f "${file}" ;then
	local new=$(cat "${file}" | grep -Ev '^\@\@|^[[:space:]]\@\@\|\||^<<|<<1023<<|^\@\@\|\||^\|\||^##|^###|^\/|\/ad\/|^:\/\/|^_|^\?|^\.|^-|^=|^:|^~|^,|^&|^#\$#|#\@#|^\$|^\||^\*|^#\%#' | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d' )
		mkdir -p "${output_folder}"
			cd "${output_folder}"
		echo "$new" >> "${file##*/}"
	fi
}

function sort_adblock_Rules() {
	local file="${2}"
	local output_folder="${1}"
	if test -f "${file}" ;then
		local new=$(cat "${file}" | grep -E "${3}" | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d' )
		rm -f "${output_folder}/${file##*/}"
			mkdir -p "${output_folder}"
			cd "${output_folder}"
		echo "$new" > "${file##*/}"
	fi
}

function add_rules_file() {
	local file="${2}"
	local output_folder="${1}"
	local new=$(cat "${file}" | grep -E "${3}" | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d' )
	if test -f "${output_folder}/${file##*/}" ;then
		mkdir -p "${output_folder}"
			cd "${output_folder}"
				echo "$new" >> "${file##*/}"
			local sort_file="`cat "${file##*/}" | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d' `"
		echo "${sort_file}" > "${file##*/}"
	fi
}

#更新README信息
function update_README_info(){
local file="${0%/*}/README.md"
test -f "${file}" && rm -rf "${file}"
cat << key > "${file}"
# 混合规则
### 自动更新(`date +'%F %T'`)
| 名称 | GIthub订阅链接 | GItlink订阅链接 |
| :-- | :-- | :-- |
| 混合规则(自动更新) | [订阅](https://raw.githubusercontent.com/lingeringsound/adblock_auto/master/miuiadblock) |
| 混合规则精简版(自动更新) | [订阅](https://raw.githubusercontent.com/lingeringsound/adblock_auto/master/miuiadblock) |

### 上游规则
<details>
<summary>点击查看上游规则</summary>
<ul>
<li> <a href="https://easylist-downloads.adblockplus.org/easylist.txt" target="_blank" > Easylist </a> </li>
<li> <a href="https://easylist-downloads.adblockplus.org/easylistchina.txt" target="_blank" > EasylistChina </a> </li>
<li> <a href="https://easylist-downloads.adblockplus.org/antiadblockfilters.txt" target="_blank" > Antiadblockfilters </a> </li>
<li> <a href="https://filters.adtidy.org/android/filters/15_optimized.txt" target="_blank" > Adguard DNS optimized </a> </li>
<li> <a href="https://filters.adtidy.org/extension/ublock/filters/11.txt" target="_blank" > Adguard mobile </a> </li>
<li> <a href="https://filters.adtidy.org/extension/ublock/filters/224.txt" target="_blank" > Adguard Chinese </a> </li>
</ul>
</details>
key
}




