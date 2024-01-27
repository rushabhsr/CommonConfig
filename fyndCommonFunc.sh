function getDbUrl(){
    allUrls=`grep -iE $1 /Users/rushabhsarvaiya/Documents/AllConnections.uri`
    silverboltUrl=`echo -e "$allUrls" | grep -i silverbolt | awk -F ":=" '{print $2}'`
    # echo -e "$silverboltUrl"
    orbisUrl=`echo -e "$allUrls" | grep -i orbis | awk -F ":=" '{print $2}'`
    # echo -e "$orbisUrl"
    finalStr=`echo -e "mongo_silverbolt_read_write: ${silverboltUrl}\nmongo_orbis_read_write: ${orbisUrl}"`
    # echo -e "$finalStr"
    echo -e "$finalStr" | pbcopy
}

function getCM(){
    complete="100"
    effort="1"
    if [ "$3" != "" ]; then
        complete="$3"
    fi
    if [ "$4" != "" ]; then
        effort="$4"
    fi
    echo -e "ID:$1;DONE:$complete;HOURS:$effort; $2"
}

# function fikFetch(){
    # echo -e '/jmpz5\n\r' | echo -e '/jmp-non-prod\n\r' | echo -e '/gcp' | fik context fetch
    # sleep 1; osascript -e 'tell application "System Events" to keystroke return' | sleep 1;osascript -e 'tell application "System Events" to keystroke return' | echo -e "/gcp" | fik context fetch
# }
function conPod(){
    #fik context fetch
    pod=`kubectl get pods | grep "$1" | grep "Running" | awk -F '    ' 'NR==1{print $1}'`
    DEBUG "Connecting to pod: $pod"
    kubectl exec -it "$pod" sh
}
export conPod

function tagdeploy() {

    if [ "$1" = "fynd" ] || [ "$1" = "jioecomm" ] || [ "$1" = "jioretailer" ]|| [ "$1" = "jmp" ] || [ "$1" = "jiomrkt" ]; then
        branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
        TAG=deploy.$1
        echo "Deploying $TAG $branch"
        git tag $TAG -f
        git push origin $TAG -f
    else
        if [ "$1" = "x0" ]; then
        TAG=deploy.fyndx0.$(date +%s)
        elif [ "$1" = "x1" ]; then
        TAG=deploy.fyndx1.$(date +%s)
        else
        TAG=deploy.$1.$(date +%s)
        fi

        echo "Deploying $TAG $branch"
        git tag $TAG
        git push origin $TAG
    fi
}

function kubedel2() {
    kubectl get pods --all-namespaces | grep "$1" | awk '{print $2 " --namespace=" $1}' | xargs kubectl delete pod
}

function tunnelsolr() {
    if [ "$1" = "fynd" ];then
        ssh -i $ssh_key -N -L 8983:10.0.12.214:8983 fynd@10.0.12.214
    elif [ "$1" = "fyndx1" ];then
        ssh -i $ssh_key -N -L 8983:10.0.60.170:8983 fynd@10.0.60.170
    elif [ "$1" = "fyndx5" ];then
        ssh -i $ssh_key -N -L 8983:10.41.145.134:8983 fynd@10.41.145.134
    elif [ "$1" = "tiraz0" ];then
        ssh -i $ssh_key -N -L 8983:10.41.48.37:8983 fynd@10.41.48.37
    elif [ "$1" = "tiraz5" ];then
        ssh -i $ssh_key -N -L 8983:10.21.48.132:8983 fynd@10.21.48.132
    elif [ "$1" = "tira" ];then
        ssh -i $ssh_key -N -L 8983:10.0.48.3:8983 fynd@10.0.48.3
    elif [ "$1" = "jmpz0" ];then
        ssh -i $ssh_key -N -L 8983:10.105.48.46:8983 fynd@10.105.48.46
    elif [ "$1" = "jmpz5" ];then
        ssh -i $ssh_key -N -L 8983:10.112.48.26:8983 fynd@10.112.48.26
    elif [ "$1" = "jiox0" ];then
        ssh -i $ssh_key -N -L 8983:10.1.10.96:8983 fynd@10.1.10.96
    elif [ "$1" = "jiox5" ];then
        ssh -i $ssh_key -N -L 8983:10.5.145.55:8983 fynd@10.5.145.55
    elif [ "$1" = "jmp" ];then
        ssh -i $ssh_key -N -L 8983:10.0.18.218:8983 fynd@10.0.18.218
    else
        ssh -i $ssh_key -N -L 8983:$1:8983 fynd@$1
    fi
}

function localkafka(){
    if [ "$1" = "start" ]
    then
        docker run --name localkafka --rm -it -d -p 3181:3181 -p 3040:3040 -p 7081:7081 -p 7082:7082 -p 7083:7083 -p 7092:7092 -e ZK_PORT=3181 -e WEB_PORT=3040 -e REGISTRY_PORT=8081 -e REST_PORT=7082 -e CONNECT_PORT=7083 -e BROKER_PORT=7092 -e ADV_HOST=127.0.0.1 faberchri/fast-data-dev
    elif [ "$1" = "stop" ]
    then
        docker stop localkafka
    elif [ "$1" = "restart" ]
    then
        docker restart localkafka
    fi
}

function localsolr(){
    if [ "$1" = "start" ]
    then
        docker run --name localsolr --rm -it -d -p 8983:8983 -t solr
    elif [ "$1" = "stop" ]
    then
        docker stop localsolr
    elif [ "$1" = "restart" ]
    then
        docker restart localsolr
    fi
}

function pfss(){
    if [ "$1" = "fynd" ];then
        kubectl port-forward service/fplt-slingshot-internl-svc 7546:80
    elif [ "$1" = "jmp" ];then
        kubectl port-forward service/jmpt-slingshot-internl-svc 7546:80
    elif [ "$1" = "jio" ];then
        kubectl port-forward service/jmrt-slingshot-internl-svc 7546:80
    elif [ "$1" = "jmkt" ];then
        kubectl port-forward service/jmkt-slingshot-internl-svc 7546:80
    elif [ "$1" = "tira" ];then
        kubectl port-forward service/tira-slingshot-internl-svc 7546:80
    else
        env=`kubectl get services | grep "slingshot-internl-svc" | awk -F "-" '{print $1}'`
        echo "Slingshot port forwarding for ENV: $env"
        kubectl port-forward service/$env-slingshot-internl-svc 7546:80
    fi
}

kube () {
    kubectl config use-context "$1"
    if [ "$?" = 1 ]; then
        kubectl config use-context "$1"
    fi
}
kubecon () {
    kubectl exec -it "$1" -- sh
}
kubeget () {
    kubectl get pods | grep -i "$1"
}
kubelog () {
    kubectl logs -f "$1"
}
kubelogall () {
    kubectl logs -f deployments/"$1"
}
kubedel() {
    kubectl get pods --all-namespaces | grep "$1" | awk '{print $2 " --namespace=" $1}' | xargs kubectl delete pod
}
killport() {  
    port=$(lsof -n -i4TCP:$1 | grep LISTEN | awk '{ print $2 }')  kill -9 $port 
}

resetenv() {
    deactivate
    echo "Deactivated"

    rm -fdr venv
    echo "VENV Deleted"

    python3.8 -m venv venv
    echo "New VENV Created"

    . venv/bin/activate
    echo "New VENV Activated"

    export C_INCLUDE_PATH=/opt/homebrew/Cellar/librdkafka/2.0.2/include
    export LIBRARY_PATH=/opt/homebrew/Cellar/librdkafka/2.0.2/lib
    echo "Installing Dependencies.."
    pip install --upgrade pip wheel
    pip install --upgrade pandas black confluent_kafka==1.5.0
    poetry install --no-cache
}
