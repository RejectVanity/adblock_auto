#!/bin/sh


#下载Adblock规则
function download_link(){
local IFS=$'\n'

target_dir="${1}"
test "${target_dir}" = "" && target_dir="`pwd`/temple/download_Rules"
mkdir -p "${target_dir}"

list='
https://easylist-downloads.adblockplus.org/antiadblockfilters.txt|antiadblockfilters.txt
https://easylist-downloads.adblockplus.org/easylist.txt|easylist.txt
https://easylist-downloads.adblockplus.org/easylistchina.txt|easylistchina.txt
https://filters.adtidy.org/android/filters/15_optimized.txt|adguard_optimized.txt
https://filters.adtidy.org/extension/ublock/filters/224.txt|Adguard_Chinese.txt
https://filters.adtidy.org/extension/ublock/filters/11.txt|Adguard_mobile.txt
'

for i in ${list}
do
test "$(echo "${i}" | grep -E '^#' )" && continue
	name=`echo "${i}" | cut -d '|' -f2`
		URL=`echo "${i}" | cut -d '|' -f1`
	test ! -f "${target_dir}/${name}" && curl -k -L -o "${target_dir}/${name}" "${URL}" >/dev/null 2>&1 && echo "※ `date +'%F %T'` ${name} 下载成功！"
dos2unix "${target_dir}/${name}" >/dev/null 2>&1
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
! Gitcode Homepage: https://gitcode.net/weixin_45617236/adblock_auto
! GitHub Homepage: https://github.com/lingeringsound/adblock_auto
! Gitcode Raw Link: https://gitcode.net/weixin_45617236/adblock_auto/-/raw/main/Rules/${file##*/}
! Github Raw Link: https://lingeringsound.github.io/adblock_auto/Rules/${file##*/}
key
echo "${original_file}" >> "${file}"
perl "`pwd`/addchecksum.pl" "${file}"
}

#净化规则
function modtify_adblock_original_file() {
local file="${1}"
if test "${2}" = "" ;then
	local new=`cat "${file}" | iconv -t 'utf8' | grep -Ev '^#\@\?#|^\$\@\$|^#\%#|^#\@\%#|^#\@\$\?#|^#\$\?#|^<<|<<1023<<' | sed 's|^[[:space:]]@@|@@|g;s|“|"|g;s|”|"|g' | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d;/^\[.*\]$/d' `
		echo "$new" > "${file}"
else
	local new=`cat "${file}" | iconv -t 'utf8' | grep -Ev '^#\@\?#|^\$\@\$|^#\%#|^#\@\%#|^#\@\$\?#|^#\$\?#|^<<|<<1023<<' | grep -Ev "${2}" | sed 's|^[[:space:]]@@|@@|g;s|“|"|g;s|”|"|g' | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d;/^\[.*\]$/d' `
		echo "$new" > "${file}"
fi
}

function make_white_rules(){
local file="${1}"
local IFS=$'\n'
local white_list_file="${2}"
for o in `cat "${white_list_file}" 2>/dev/null | sed '/^!/d;/^[[:space:]]*$/d' `
do
`pwd`/busybox sed -i "/${o}/d" "${file}"
done
}

function fix_Rules(){
local file="${1}"
local target_content="${2}"
local fix_content="${3}"
test ! -f "${file}" -o "${fix_content}" = "" && return 
`pwd`/busybox sed -i "s|${target_content}|${fix_content}|g" "${file}"
}

function Combine_adblock_original_file(){
local file="${1}"
local target_folder="${2}"
test "${target_folder}" = "" && echo "※`date +'%F %T'` 请指定合并目录……" && exit
for i in "${target_folder}"/*.txt
do
	dos2unix "${i}" >/dev/null 2>&1
	echo "`cat "${i}"`" >> "${file}"
done
}

#筛选整理规则
function wipe_white_list() {
	local file="${2}"
	local output_folder="${1}"
	if test -f "${file}" ;then
	local new=$(cat "${file}" | grep -Ev "${3}" | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d' )
		mkdir -p "${output_folder}"
		echo "$new" > "${output_folder}/${file##*/}"
	fi
}

function sort_web_rules() {
	local file="${2}"
	local output_folder="${1}"
	if test -f "${file}" ;then
	local new=$(cat "${file}" | grep -Ev '^\@\@|^[[:space:]]\@\@\|\||^<<|<<1023<<|^\@\@\|\||^\|\||^##|^###|^\/|\/ad\/|^:\/\/|^_|^\?|^\.|^-|^=|^:|^~|^,|^&|^#\$#|#\@#|^\$|^\||^\*|^#\%#' | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d' )
		mkdir -p "${output_folder}"
		echo "$new" >> "${output_folder}/${file##*/}"
	fi
}

function sort_adblock_Rules() {
	local file="${2}"
	local output_folder="${1}"
	if test -f "${file}" ;then
		local new=$(cat "${file}" | grep -E "${3}" | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d' )
			mkdir -p "${output_folder}"
		echo "$new" > "${output_folder}/${file##*/}"
	fi
}

function add_rules_file() {
	local file="${2}"
	local output_folder="${1}"
	local new=$(cat "${file}" | grep -E "${3}" | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d' )
	if test -f "${output_folder}/${file##*/}" ;then
		mkdir -p "${output_folder}"
				echo "$new" >> "${output_folder}/${file##*/}"
			local sort_file=`cat "${output_folder}/${file##*/}" | sort | uniq | sed '/^!/d;/^[[:space:]]*$/d' `
		echo "${sort_file}" > "${output_folder}/${file##*/}"
	fi
}

#测试github 加速的链接
function Get_Download_github_raw_link(){
local download_target="${1}"
if test "`ping -c 1 -W 3 raw.fgit.ml >/dev/null 2>&1 && echo 'yes'`" = "yes" ;then
	target="`echo ${download_target} | sed 's|raw.githubusercontent.com|raw.fgit.ml|g'`"
elif test "`ping -c 1 -W 3 ghproxy.com >/dev/null 2>&1 && echo 'yes'`" = "yes" ;then
	target="https://ghproxy.com/${download_target}"
elif test "`ping -c 1 -W 3 raw.gitmirror.com >/dev/null 2>&1 && echo 'yes'`" = "yes" ;then
	target="`echo ${download_target} | sed 's|raw.githubusercontent.com|raw.gitmirror.com|g'`"
elif test "`ping -c 1 -W 3 raw.iqiq.io >/dev/null 2>&1 && echo 'yes'`" = "yes" ;then
	target="`echo ${download_target} | sed 's|raw.githubusercontent.com|raw.iqiq.io|g'`"
elif test "`ping -c 1 -W 3 raw.fastgit.org >/dev/null 2>&1 && echo 'yes'`" = "yes" ;then
	target="`echo ${download_target} | sed 's|raw.githubusercontent.com|raw.fastgit.org|g'`"
else
	echo "${download_target}" | grep -q 'raw.githubusercontent.com' && echo "[E]`date +'%F %T'` 错误！无法连接网络！" && exit 1
fi
	echo "${target}"
}

#shell 特殊字符转义
function escape_special_chars(){
	local input=${1}
	local output=$(echo ${input} | sed 's/[\^\|\*\?\$\=\@\/\.\"]/\\&/g;s|\[|\\&|g;s|\]|\\&|g' )
	echo ${output}
}

#去除指定重复的Css
function sort_Css_Combine(){
local target_content="${2}"
local target_file="${1}"
local target_file_tmp="`pwd`/${target_file##*/}.tmp"
local target_output_file="`pwd`/${target_file##*/}.temple"
local transfer_content=$(escape_special_chars ${target_content})
#echo "${transfer_content}$"
grep -E "${transfer_content}$" "${target_file}" > "${target_file_tmp}" 
if test "$(cat ${target_file_tmp} 2>/dev/null | sed 's|#.*||g' | grep -E ',')" != "" ;then
	sed -i 's|#.*||g' "${target_file_tmp}"
	local before_tmp=$(cat "${target_file_tmp}" | tr ',' '\n' | sed '/^[[:space:]]*$/d' | sort -u | uniq )
	echo "${before_tmp}" > "${target_file_tmp}"
	sed -i ":a;N;\$!ba;s#\n#,#g" "${target_file_tmp}"
	if test "$(cat "${target_file_tmp}" 2>/dev/null | sed '/^!/d;/^[[:space:]]*$/d' )" != "" ;then 
		grep -Ev "${transfer_content}$" "${target_file}" >> "${target_output_file}" 
		echo "`cat "${target_file_tmp}"`${target_content}" >> "${target_output_file}"
		echo "${css_common_record}" >> "${target_output_file}"
		mv -f "${target_output_file}" "${target_file}"
	fi
else
	sed -i 's|#.*||g' "${target_file_tmp}"
	local before_tmp=$(cat "${target_file_tmp}" | sed '/^[[:space:]]*$/d' | sort -u | uniq)
	echo "${before_tmp}" > "${target_file_tmp}"
	if test "$(cat "${target_file_tmp}" 2>/dev/null | sed '/^!/d;/^[[:space:]]*$/d' | wc -l)" -gt "1" ;then
		sed -i ":a;N;\$!ba;s#\n#,#g" "${target_file_tmp}"
	fi
	if test "$(cat "${target_file_tmp}" 2>/dev/null | sed '/^!/d;/^[[:space:]]*$/d' )" != "" ;then 
		grep -Ev "${transfer_content}$" "${target_file}" >> "${target_output_file}" 
		echo "`cat "${target_file_tmp}"`${target_content}" >> "${target_output_file}" 
		echo "${css_common_record}" >> "${target_output_file}"
		mv -f "${target_output_file}" "${target_file}"
	fi
fi
rm -rf "${target_file_tmp}" 2>/dev/null
}

#去除重复作用的域名
function sort_domain_Combine(){
local target_content="${2}"
local target_file="${1}"
local target_file_tmp="`pwd`/${target_file##*/}.tmp"
local target_output_file="`pwd`/${target_file##*/}.temple"
local transfer_content=$(escape_special_chars ${target_content})
grep -E "^${transfer_content}" "${target_file}" > "${target_file_tmp}" 
if test "$(cat ${target_file_tmp} 2>/dev/null | sed 's|.*domain=||g' | grep -E ',')" != "" ;then
	return
elif test "$(cat ${target_file_tmp} 2>/dev/null | sed 's|.*domain=||g' | grep -E '\|')" != "" ;then
	sed -i 's|.*domain=||g' "${target_file_tmp}"
	local before_tmp=$(cat "${target_file_tmp}" | tr '|' '\n' | sed '/^[[:space:]]*$/d' | sort -u | uniq)
	echo "${before_tmp}" > "${target_file_tmp}"
	sed -i ":a;N;\$!ba;s#\n#\|#g" "${target_file_tmp}"
	if test "$(cat "${target_file_tmp}" 2>/dev/null | sed '/^!/d;/^[[:space:]]*$/d' )" != "" ;then 
		grep -Ev "^${transfer_content}" "${target_file}" >> "${target_output_file}" 
		echo "${target_content}`cat "${target_file_tmp}"`" >> "${target_output_file}" 
		mv -f "${target_output_file}" "${target_file}"
	fi
else
	sed -i 's|.*domain=||g' "${target_file_tmp}"
	local before_tmp=$(cat "${target_file_tmp}" | sed '/^[[:space:]]*$/d' | sort -u | uniq)
	echo "${before_tmp}" > "${target_file_tmp}"
	if test "$(cat "${target_file_tmp}" 2>/dev/null | sed '/^!/d;/^[[:space:]]*$/d' | wc -l)" -gt "1" ;then
		sed -i ":a;N;\$!ba;s#\n#\|#g" "${target_file_tmp}"
	fi
	if test "$(cat "${target_file_tmp}" 2>/dev/null | sed '/^!/d;/^[[:space:]]*$/d' )" != "" ;then 
		grep -Ev "^${transfer_content}" "${target_file}" >> "${target_output_file}" 
		echo "${target_content}`cat "${target_file_tmp}"`" >> "${target_output_file}" 
		mv -f "${target_output_file}" "${target_file}"
	fi
fi
rm -rf "${target_file_tmp}" 2>/dev/null
}

#避免大量字符影响观看
function Running_sort_domain_Combine(){
local IFS=$'\n'
local target_adblock_file="${1}"
test ! -f "${target_adblock_file}" && echo "※`date +'%F %T'` ${target_adblock_file} 规则文件不存在！！！" && return
sort_domain_Combine "${target_adblock_file}" '?*=*=*=$subdocument,domain='
sort_domain_Combine "${target_adblock_file}" '$script,third-party,websocket,domain='
sort_domain_Combine "${target_adblock_file}" '$script,third-party,domain='
sort_domain_Combine "${target_adblock_file}" '$script,subdocument,~third-party,websocket,xmlhttprequest,domain='
sort_domain_Combine "${target_adblock_file}" '$script,subdocument,third-party,websocket,xmlhttprequest,domain='
sort_domain_Combine "${target_adblock_file}" '$script,subdocument,third-party,domain='
sort_domain_Combine "${target_adblock_file}" '$image,third-party,domain='
sort_domain_Combine "${target_adblock_file}" '.gif$third-party,domain='
sort_domain_Combine "${target_adblock_file}" '.gif^$domain=' 
sort_domain_Combine "${target_adblock_file}" '/advert-$domain='
sort_domain_Combine "${target_adblock_file}" '/advert.$~script,domain='
sort_domain_Combine "${target_adblock_file}" '/adcore.$domain='
sort_domain_Combine "${target_adblock_file}" '||taobao.com^$popup,domain='
sort_domain_Combine "${target_adblock_file}" '||pagead2.googlesyndication.com^$important,script,redirect=googlesyndication-adsbygoogle,domain='
sort_domain_Combine "${target_adblock_file}" '||pagead2.googlesyndication.com^$important,script,redirect=googlesyndication_adsbygoogle.js,domain='
sort_domain_Combine "${target_adblock_file}" '||pagead2.googlesyndication.com^$important,script,redirect=noopjs,domain='
sort_domain_Combine "${target_adblock_file}" '||pagead2.googlesyndication.com/pagead/js/adsbygoogle.js$script,redirect=noop.js,domain='
sort_domain_Combine "${target_adblock_file}" '||pagead2.googlesyndication.com/pagead/js/adsbygoogle.js$redirect=googlesyndication-adsbygoogle,domain='
sort_domain_Combine "${target_adblock_file}" '||pagead2.googlesyndication.com/pagead/js/adsbygoogle.js$script,redirect=googlesyndication-adsbygoogle,domain='
sort_domain_Combine "${target_adblock_file}" '||pagead2.googlesyndication.com/pagead/js/adsbygoogle.js$script,redirect=googlesyndication.com/adsbygoogle.js,domain='
sort_domain_Combine "${target_adblock_file}" '||pagead2.googlesyndication.com^$important,script,redirect=googlesyndication-adsbygoogle,domain='
sort_domain_Combine "${target_adblock_file}" '||pagead2.googlesyndication.com/pagead/js/adsbygoogle.js$script,redirect=noopjs,domain='
sort_domain_Combine "${target_adblock_file}" '://ads.$~image,domain='
sort_domain_Combine "${target_adblock_file}" '://adv.$domain='
sort_domain_Combine "${target_adblock_file}" '/adflow.$domain='
sort_domain_Combine "${target_adblock_file}" '@@||pagead2.googlesyndication.com/pagead/js/adsbygoogle.js$domain='
sort_domain_Combine "${target_adblock_file}" '@@||pagead2.googlesyndication.com/pagead/js/*/show_ads_impl.js$domain='
sort_domain_Combine "${target_adblock_file}" '?advertiserid=$domain='


}


#避免大量字符影响观看
function Running_sort_Css_Combine(){
local target_adblock_file="${1}"
test ! -f "${target_adblock_file}" && echo "※`date +'%F %T'` ${target_adblock_file} 规则文件不存在！！！" && return
#记录通用的Css
local css_common_record="$(cat ${target_adblock_file} 2>/dev/null | sed '/^!/d;/^[[:space:]]*$/d;/^#/!d' )"
sort_Css_Combine "${target_adblock_file}" '##.ad'
sort_Css_Combine "${target_adblock_file}" '##.Ad'
sort_Css_Combine "${target_adblock_file}" '##.AD'
sort_Css_Combine "${target_adblock_file}" '##.ads'
sort_Css_Combine "${target_adblock_file}" '##.Ads'
sort_Css_Combine "${target_adblock_file}" '##.ADS'
sort_Css_Combine "${target_adblock_file}" '##.adv'
sort_Css_Combine "${target_adblock_file}" '##.advert'
sort_Css_Combine "${target_adblock_file}" '##.advertising'
sort_Css_Combine "${target_adblock_file}" '##.advertisement'
sort_Css_Combine "${target_adblock_file}" '##.advertisment'
sort_Css_Combine "${target_adblock_file}" '##.advertise'
sort_Css_Combine "${target_adblock_file}" '##.sponsor'
sort_Css_Combine "${target_adblock_file}" '###advertising'
sort_Css_Combine "${target_adblock_file}" '#@##advertise'
sort_Css_Combine "${target_adblock_file}" '##.banner'
sort_Css_Combine "${target_adblock_file}" '###diynavtop'
sort_Css_Combine "${target_adblock_file}" '##.mpu'
sort_Css_Combine "${target_adblock_file}" '##.promoted-block'
sort_Css_Combine "${target_adblock_file}" '##div[id^="ad"]'
sort_Css_Combine "${target_adblock_file}" '##div[id^="AD"]'
sort_Css_Combine "${target_adblock_file}" '##div[class^="ad_"]'
sort_Css_Combine "${target_adblock_file}" '##div[class^="adv"]'
sort_Css_Combine "${target_adblock_file}" '##div[class^="ads-"]'
sort_Css_Combine "${target_adblock_file}" '##body > a'
sort_Css_Combine "${target_adblock_file}" '##[style*="blob:"]'
sort_Css_Combine "${target_adblock_file}" '##[style*="base64"]'
sort_Css_Combine "${target_adblock_file}" '##[href*="data:"]'
sort_Css_Combine "${target_adblock_file}" '##a[href*="?ats="]'
sort_Css_Combine "${target_adblock_file}" '##[src^="bLob:"]'
sort_Css_Combine "${target_adblock_file}" '##[style*="blob:"]'
sort_Css_Combine "${target_adblock_file}" '##[href*="base64"]'
sort_Css_Combine "${target_adblock_file}" '##a[href^="http://ads.trafficjunky.net/"]'
sort_Css_Combine "${target_adblock_file}" '##a[href^="https://ads.trafficjunky.net/"]'
sort_Css_Combine "${target_adblock_file}" '##body > a[target="_blank"]'
sort_Css_Combine "${target_adblock_file}" '##.d-lg-block'
sort_Css_Combine "${target_adblock_file}" '##.bottom_fixed'
sort_Css_Combine "${target_adblock_file}" '##div[onclick*="bp1.com"]'
sort_Css_Combine "${target_adblock_file}" '##img[src*="data:"]'
sort_Css_Combine "${target_adblock_file}" '##[srcdoc]'
sort_Css_Combine "${target_adblock_file}" '##HTML'
sort_Css_Combine "${target_adblock_file}" '##canvas'
sort_Css_Combine "${target_adblock_file}" '##.sticky-container'
sort_Css_Combine "${target_adblock_file}" '##.top-banner'
sort_Css_Combine "${target_adblock_file}" '#@#.adsbygoogle'
sort_Css_Combine "${target_adblock_file}" '##.bottom-banners'
sort_Css_Combine "${target_adblock_file}" '##.happy-under-player'
sort_Css_Combine "${target_adblock_file}" '##.ai_widget'
sort_Css_Combine "${target_adblock_file}" '##.header-billboard'
sort_Css_Combine "${target_adblock_file}" '##.td-a-rec'
sort_Css_Combine "${target_adblock_file}" '##canvas'
sort_Css_Combine "${target_adblock_file}" '###banner'
sort_Css_Combine "${target_adblock_file}" '##.ad2'
sort_Css_Combine "${target_adblock_file}" '##.spot'
sort_Css_Combine "${target_adblock_file}" '##img[height="90"]'
sort_Css_Combine "${target_adblock_file}" '##img[width="300"]'
sort_Css_Combine "${target_adblock_file}" '##.leaderboard'
sort_Css_Combine "${target_adblock_file}" '##.google'
sort_Css_Combine "${target_adblock_file}" '##.slot'
sort_Css_Combine "${target_adblock_file}" '##a[href*="theporndude.com"]'
sort_Css_Combine "${target_adblock_file}" '#@#ins.adsbygoogle'
sort_Css_Combine "${target_adblock_file}" '#@#.advertiser'
sort_Css_Combine "${target_adblock_file}" '#@#.video-ads'
sort_Css_Combine "${target_adblock_file}" '##.header-banner'
sort_Css_Combine "${target_adblock_file}" '##a[href^="http://t.cn/"]'
sort_Css_Combine "${target_adblock_file}" '##a[href*=".tmall.com"]'
sort_Css_Combine "${target_adblock_file}" '##.widget_media_image'


#写入通用的Css
echo "${css_common_record}" >> "${target_adblock_file}"
}

#更新README信息
function update_README_info(){
local file="`pwd`/README.md"
test -f "${file}" && rm -rf "${file}"
cat << key > "${file}"
# 混合规则
### 自动更新(`date +'%F %T'`)


| 名称 | GIthub订阅链接 | Github加速订阅链接 | GitCode订阅链接 | Gitlab订阅链接 |
| :-- | :-- | :-- | :-- | :-- |
| 混合规则(自动更新) | [订阅](https://raw.githubusercontent.com/lingeringsound/adblock_auto/main/Rules/adblock_auto.txt) | [订阅](https://raw.fgit.ml/lingeringsound/adblock_auto/main/Rules/adblock_auto.txt) | [订阅](https://gitcode.net/weixin_45617236/adblock_auto/-/raw/main/Rules/adblock_auto.txt) | [订阅](https://jihulab.com/foreseeable_boy/adblock_auto/-/raw/main/Rules/adblock_auto.txt) |
| 混合规则精简版(自动更新) | [订阅](https://raw.githubusercontent.com/lingeringsound/adblock_auto/main/Rules/adblock_auto_lite.txt) | [订阅](https://raw.fgit.ml/lingeringsound/adblock_auto/main/Rules/adblock_auto_lite.txt) | [订阅](https://gitcode.net/weixin_45617236/adblock_auto/-/raw/main/Rules/adblock_auto_lite.txt) | [订阅](https://jihulab.com/foreseeable_boy/adblock_auto/-/raw/main/Rules/adblock_auto_lite.txt) |

### 拦截器说明
> #### [混合规则(自动更新)](https://lingeringsound.github.io/adblock_auto/Rules/adblock_auto.txt) 适用于 \`Adguard\` / \`Ublock Origin\` / \`Adblock Plus\`(用Adblock Plus源码编译的软件也支持，例如[嗅觉浏览器](https://www.coolapk.com/apk/com.hiker.youtoo) ) 支持复杂语法的过滤器，或者能兼容大规则的浏览器例如 [X浏览器](https://www.coolapk.com/apk/com.mmbox.xbrowser)

> #### [混合规则精简版(自动更新)](https://lingeringsound.github.io/adblock_auto/Rules/adblock_auto_lite.txt) 适用于轻量的浏览器，例如  [VIA](https://www.coolapk.com/apk/mark.via)  / [Rian](https://www.coolapk.com/apk/com.rainsee.create) / [B仔浏览器](https://www.coolapk.com/apk/com.huicunjun.bbrowser)


### 上游规则
#### 感谢各位大佬❤ (ɔˆз(ˆ⌣ˆc)
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


