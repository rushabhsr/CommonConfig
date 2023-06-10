#alaises
alias ls='ls --color=always'
alias ll='ls -lrth'
alias ls20='ls -lrth | tail -20'
export getCM
function DEBUG(){
    echo -e "`date +%a_%d_%m_%y%H_%M_%S`: $1"
}
export DEBUG

. "$OSH"/fyndCommonFunc.sh