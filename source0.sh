echo "这是个脚本source文件"

function ftest() {
    echo "f test"
}


#git仓库过大, 永久删除文件   开始----------------

#查看大文件
git rev-list --objects --all | grep -E `git verify-pack -v .git/objects/pack/*.idx | sort -k 3 -n | tail -10 | awk '{print$1}' | sed ':a;N;$!ba;s/\n/|/g'`
#或
git rev-list --objects --all | grep "$(git verify-pack -v .git/objects/pack/*.idx | sort -k 3 -n | tail -15 | awk '{print$1}')"

#永久删除git库的物理文件
#注意：命令中的 path/largefiles 是大文件所在的路径，千万不要弄错！ 在路径前加-r表示递归的删除（子）文件夹和文件夹下的文件
#如果在 git filter-branch 操作过程中出错，需要在 git filter-branch 后面加上参数 -f
git filter-branch --tree-filter 'rm -f path/largefiles' --tag-name-filter cat -- --all

#同步
git push origin --tags --force
git push origin --all --force
#git仓库过大, 永久删除文件   结束----------------
