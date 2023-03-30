#!/bin/sh

#加载公共函数
source "`pwd`/until_function.sh"

#指定目录和输出文件
Sort_Folder="`pwd`/temple/sort" 
Download_Folder="`pwd`/temple/download_Rules"
Combine_Folder="`pwd`/temple/combine"
Rules_Folder="`pwd`/Rules"
Base_Rules_Folder="`pwd`/base"

#创建目录
mkdir -p "${Download_Folder}" "${Sort_Folder}/lite" "${Combine_Folder}/lite" "${Rules_Folder}" && echo "※`date +'%F %T'` 创建临时目录成功！"

#下载规则
download_link "${Download_Folder}"

#处理规则
#Easylist 公共规则
echo "※`date +'%F %T'` 开始处理Easylist规则……"
wipe_white_list "${Sort_Folder}" "${Download_Folder}/easylistchina.txt" '^\@\@|^[[:space:]]\@\@\|\||^<<|<<1023<<|^\@\@\|\||^\|\|'
add_rules_file "${Sort_Folder}" "${Download_Folder}/easylistchina.txt" '^\|\|.*\^$'
sort_adblock_Rules "${Sort_Folder}" "${Download_Folder}/easylist.txt" '^##|^###|^\/|\/ad\/|^:\/\/|^_|^\?|^\.|^-|^=|^:|^~|^,|^&'
sort_web_rules "${Sort_Folder}" "${Download_Folder}/easylist.txt" 
#lite规则
echo "※`date +'%F %T'` 开始处理精简版规则……"
sort_adblock_Rules "${Sort_Folder}/lite" "${Download_Folder}/Adguard_Chinese.txt" '^\|\||^#'
sort_adblock_Rules "${Sort_Folder}/lite" "${Download_Folder}/Adguard_mobile.txt" '^\|\||^#'
#full规则
echo "※`date +'%F %T'` 开始处理完整版规则……"
wipe_white_list "${Sort_Folder}" "${Download_Folder}/Adguard_Chinese.txt" '^\@\@|^[[:space:]]\@\@\|\||^<<|<<1023<<|\@\@\|\|'
wipe_white_list "${Sort_Folder}" "${Download_Folder}/adguard_optimized.txt" '^\@\@|^[[:space:]]\@\@\|\||^<<|<<1023<<|\@\@\|\|'
sort_adblock_Rules "${Sort_Folder}" "${Download_Folder}/Adguard_mobile.txt" '^##|^###|^\/|\/ad\/|^:\/\/|^_|^\?|^\.|^-|^=|^:|^~|^,|^&|^\|\||^#\$#|^#\?#'

#合并规则
echo "※`date +'%F %T'` 开始合并规则……"
#Full
Combine_adblock_original_file "${Combine_Folder}/adblock_combine.txt" "${Sort_Folder}"
cp -rf "${Base_Rules_Folder}/adblock" "${Combine_Folder}/adblock.txt"
cp -rf "${Base_Rules_Folder}/其他.prop" "${Combine_Folder}/其他.txt"
Combine_adblock_original_file "${Rules_Folder}/adblock_auto.txt" "${Combine_Folder}"
modtify_adblock_original_file "${Rules_Folder}/adblock_auto.txt"
#make_white_rules "${Rules_Folder}/adblock_auto.txt" "`pwd`/white_list/white_list.prop"
write_head "${Rules_Folder}/adblock_auto.txt" "混合规则(自动更新)" && echo "※`date +'%F %T'` 混合规则合并完成！"
#lite
Combine_adblock_original_file "${Combine_Folder}/lite/adblock_combine.txt" "${Sort_Folder}/lite"
cp -rf "${Base_Rules_Folder}/adblock_lite" "${Combine_Folder}/lite/adblock_lite.txt"
cp -rf "${Base_Rules_Folder}/其他.prop" "${Combine_Folder}/lite/其他.txt"
Combine_adblock_original_file "${Rules_Folder}/adblock_auto_lite.txt" "${Combine_Folder}/lite"
modtify_adblock_original_file "${Rules_Folder}/adblock_auto_lite.txt"
#make_white_rules "${Rules_Folder}/adblock_auto_lite.txt" "`pwd`/white_list/white_list.prop"
write_head "${Rules_Folder}/adblock_auto_lite.txt" "混合规则精简版(自动更新)" && echo "※`date +'%F %T'` 混合规则精简版合并完成！"

rm -rf "`pwd`/temple"
#更新README信息
update_README_info



