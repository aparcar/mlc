#!/bin/bash
set +x

. ./mlc-vars.sh
mlc_cpu_idle_assumption=35
#set -x

ANA_SSH="$mlc_ssh -i /home/neumann/.ssh/id_rsa "
ANA_MLC_DIR="/home/neumann/mlc-public.git"
ANA_OWRT_DIR="/home/neumann/openwrt/openwrt-15.05.git"
ANA_RESULTS_DIR="$ANA_MLC_DIR/ana"
ANA_RESULTS_FILE_PREFIX="results-01"
ANA_PROT_DIR="/usr/src/bmx7.git"
ANA_NODE_TRUSTED_DIR="etc/bmx7/trustedNodes"
ANA_NODE_ATTACKED_DIR="etc/bmx7/attackedNodes"
ANA_NODE_KEYS_DIR="usr/src/bmxKeys"
ANA_MLC_KEYS_DIR=$ANA_MLC_DIR/rootfs/mlc0002/rootfs/$ANA_NODE_KEYS_DIR

ANA_NODES_DEF=100 # 100
ANA_NODES_MIN=10

ANA_LINKS_DEF=4
ANA_LINKS_MIN=1
ANA_LINKS_MAX=20

ANA_LINK_KEY_LEN=896
ANA_NODE_KEY_LEN=${1:-2048}

echo "ANA_NODE_KEY_LEN=$ANA_NODE_KEY_LEN"

ANA_MBR=1
ANA_LQ=3
ANA_PROTO=bmx7
ANA_PROTO_RM="/usr/lib/bmx7* /etc/config/bmx7"
ANA_MLC_DEVS="dev=eth1"
#ANA_DST_DEVS="dev=br-lan dev=wlan0 /l=1"
ANA_DST_DEVS="dev=br-lan"

ANA_PROTO_CMD="bmx7 d=0"
ANA_UDP_PORT="6270"

################################
# for attack scenarios:
ANA_NODES_MAX=165 # 150
ANA_ATTACK_PEN_LEVEL=0
ANA_ATTACK_TOPO_COLS=15
ANA_ATTACK_TOPO_ROLES=3
ANA_MAIN_OPTS="linkSignatureLen=$ANA_LINK_KEY_LEN trustedNodesDir=/$ANA_NODE_TRUSTED_DIR attackedNodesDir=/$ANA_NODE_ATTACKED_DIR evilRouteDropping=1 evilDescDropping=1"

# for owrt perf scenarios:
ANA_NODES_MAX=200
ANA_ATTACK_PEN_LEVEL=0
ANA_ATTACK_TOPO_COLS=10
ANA_ATTACK_TOPO_ROLES=1
ANA_MAIN_OPTS="linkSignatureLen=$ANA_LINK_KEY_LEN trustedNodesDir=/$ANA_NODE_TRUSTED_DIR"
################################


ANA_DST_DEV=eth1
ANA_DST_SRC=192.168.1.76/24
ANA_DST1_MAC=14:cf:92:52:0f:10
ANA_DST1_IP4=192.168.1.101
ANA_DST2_MAC=14:cf:92:52:13:a6
ANA_DST2_IP4=192.168.1.102
ANA_DST_SYS=""
ANA_DST_PACKAGES="$ANA_OWRT_DIR/bin/ar71xx/packages/routing/bmx7_*.ipk"
ANA_DST_BMX7_UPD="ana-owrt-bmx7-upd.sh"
ANA_DST_FILES="$ANA_MLC_DIR/$ANA_DST_BMX7_UPD"


ANA_E2E_DST=mlc1003
ANA_E2E_SRC4=10.0.10.0

ANA_PING_DEADLINE=20
ANA_STABILIZE_TIME=120
ANA_MEASURE_TIME=25
ANA_MEASURE_ROUNDS=1
ANA_MEASURE_PROBES=10
ANA_MEASURE_GAP=2
ANA_UPD_PERIOD=1
ANA_RESULTS_FILE="$ANA_MLC_DIR/ana/results.dat"
ANA_RT_LOAD=1
ANA_RT_RAISE_TIME=6
ANA_PROBE_DELAY_TIME=3
ANA_PROBE_SAFE_TIME=30



ANA_NODE_MAX=$((( $mlc_min_node + $ANA_NODES_MAX - 1 )))
ANA_ATTACK_ROLE_COLORS=(orange rosa cyan)
ANA_CPA_ATTACK_NODE="1009"
ANA_CPA_TRUST_NODES="1002 1007 1152 1157"
ANA_NODE_PROBE_PAIRS="1002:1152 1007:1157 1012:1162 1012:1152 1012:1157"


ANA_ATTACK_OF_DIR="$ANA_MLC_DIR/ana"
ANA_ATTACK_OF_PREFIX="role"
ANA_ROLE_FILE_FORMAT="%-8s %-9s %-8s %-5s %-12s %-8s %-40s %-35s %8s %8s %6s %6s %8s %9s\n"
ANA_ROLE_FILE_HEADER="topoCols  topoNodes  penLevel  mlcId  mlcIp  nodeName  nodeId  nodeIp  nodeCol  nodeLine  nRLMin        nRLMax        nodeRole  nodeColor"
ANA_ROLE_FILE_COL_MLCID=3
ANA_ROLE_FILE_COL_MLCIP=4
ANA_ROLE_FILE_COL_NODEROLE=12
ANA_ROLE_FILE_COL_NODECOLOR=13
ANA_ROLE_FILE_COL_NAME=5
ANA_ROLE_FILE_COL_NODEID=6
ANA_ROLE_FILE_COL_NODEIP=7

ANA_TRUST_TABLE=( \
    1 0 1 \
    0 1 1 \
    1 1 1 )

ANA_ATTACK_TABLE=( \
    0 1 0 \
    1 0 0 \
    0 0 0 )




ana_time_stamp() {
    date +%Y%m%d-%H%M%S
}

ana_update_mlc() {
    ssh root@mlc "cd $ANA_PROT_DIR && \
	make clean_all build_all install EXTRA_CFLAGS='-pg -DPROFILING -DCORE_LIMIT=20000 -DTRAFFIC_DUMP -DCRYPTLIB=POLARSSL_1_3_3'"
}


ana_update_dst() {

    [ "$ANA_DST_SYS" ] &&  scp $ANA_DST_SYS root@$ANA_DST1_IP4:/tmp/
    [ "$ANA_DST_FILES" ] && scp $ANA_DST_FILES root@$ANA_DST1_IP4:/tmp/

#   [ "$ANA_DST_SYS" ] &&  scp $ANA_DST_SYS root@$ANA_DST2_IP4:/tmp/
#   [ "$ANA_DST_FILES" ] && scp $ANA_DST_FILES root@$ANA_DST2_IP4:/tmp/
    
    if [ "$ANA_DST_PACKAGES" ]; then
	ssh root@$ANA_DST1_IP4 rm /tmp/*.ipk
echo    scp $ANA_DST_PACKAGES root@$ANA_DST1_IP4:/tmp/
	scp $ANA_DST_PACKAGES root@$ANA_DST1_IP4:/tmp/
	ssh root@$ANA_DST1_IP4 opkg install /tmp/*.ipk

#	ssh root@$ANA_DST2_IP4 rm /tmp/*.ipk
#	scp $ANA_DST_PACKAGES root@$ANA_DST2_IP4:/tmp/
#	ssh root@$ANA_DST2_IP4 opkg install /tmp/*.ipk
    fi
}

ana_create_nodes() {
    if [ "$(mlc_ls | grep RUNNING | wc -l)" = "$((( $ANA_NODES_MAX + 1 )))" ]; then
	echo "already $ANA_NODES_MAX + 1 nodes RUNNING"
    else
	mlc_loop -a $ANA_NODE_MAX -cb
	mlc_qdisc_prepare
	[ "$(mlc_ls | grep RUNNING | wc -l)" = "$((( $ANA_NODES_MAX + 1 )))" ] || echo "MISSING NODES"
    fi

    # ANA_PROTO_RM:
    rm -f $ANA_MLC_DIR/rootfs/mlc*/rootfs/etc/config/bmx7
    rm -f $ANA_MLC_DIR/rootfs/mlc*/rootfs/usr/lib/bmx7_*


    killall -w iperf
    mlc_loop -a 1009 -e "iperf -Vs > /dev/null 2>&1 &"
    mlc_loop -a $ANA_NODE_MAX -e "echo 10 > /proc/sys/net/ipv6/icmp/ratelimit"

}




ana_create_protos_dst() {

    local nodes=${1:-$ANA_NODES_DEF}
    local rsaLen=${2:-"$ANA_NODE_KEY_LEN"}

    local ANA_DST_CMD="$ANA_PROTO_CMD nodeSignatureLen=$rsaLen /keyPath=/etc/bmx7/rsa.$rsaLen $ANA_MAIN_OPTS $ANA_DST_DEVS >/tmp/bmx7.log&"

    if [ "$nodes" = "0" ]; then

	$ANA_SSH root@$ANA_DST1_IP4 "killall $ANA_DST_BMX7_UPD; while killall $ANA_PROTO; do timeout 0.2 sleep 1d; done; rm -f $ANA_PROTO_RM"

    else
	$ANA_SSH root@$ANA_DST1_IP4 "$ANA_DST_CMD"
	$ANA_SSH root@$ANA_DST1_IP4 "ip6tables --flush; ip6tables -P FORWARD ACCEPT"
#	$ANA_SSH root@$ANA_DST1_IP4 "ip6tables -I INPUT -i br-lan -s fe80::16cf:92ff:fe52:13a6 -j DROP"
    fi
}

ana_create_protos_mlc() {
    local nodes=${1:-$ANA_NODES_DEF}
    local rsaLen=${2:-"$ANA_NODE_KEY_LEN"}

#   local ANA_MLC_CMD="$ANA_PROTO_CMD plugin=bmx7_evil.so nodeSignatureLen=$rsaLen /keyPath=/etc/bmx7/rsa.$rsaLen $ANA_MAIN_OPTS $ANA_MLC_DEVS >/root/bmx7.log& sleep 3"
    local ANA_MLC_CMD="rm -rf /root/bmx7/*; mkdir -p /root/bmx7; cd /root/bmx7; ulimit -c 20000; \
   $ANA_PROTO_CMD nodeSignatureLen=$rsaLen /keyPath=/etc/bmx7/rsa.$rsaLen $ANA_MAIN_OPTS nodeVerification=0 linkVerification=0 $ANA_MLC_DEVS /strictSignatures=1 \
   > /root/bmx7/bmx7.log 2>&1 &"




    if [ "$nodes" = "0" ]; then
	killall -w $ANA_PROTO

    else

#	[ $nodes -lt $ANA_NODES_MAX ] && \
#	    mlc_loop -i $((( 1000 + $nodes ))) -a $((( 1000 + $ANA_NODES_MAX - 1))) -e "killall -w $ANA_PROTO"

	local bmxPs=$(ps aux | grep "$ANA_PROTO_CMD" | grep -v grep | wc -l)

	[ $nodes -gt $bmxPs ] && \
	    mlc_loop -li $(((1000 + $bmxPs ))) -a $((( 1000 + $nodes - 1))) -e "$ANA_MLC_CMD"

	[ $nodes -gt $ANA_LINKS_MAX ] && \
	    mlc_loop -li $(((1000 + $ANA_LINKS_MAX ))) -a $((( 1000 + $nodes - 1))) -e "bmx7 -c $ANA_MLC_DEVS /strictSignatures=0"
    fi
}

ana_create_protos() {
    local nodes=${1:-$ANA_NODES_DEF}
    local rsaLen=${2:-"$ANA_NODE_KEY_LEN"}
    ana_create_protos_dst $nodes $rsaLen
    ana_create_protos_mlc $nodes $rsaLen
}





ana_create_net_owrt() {
    mlc_net_flush
    mlc_configure_grid $ANA_MBR $ANA_LQ 0 0 0
}

ana_create_links_owrt() {
    local links=${1:-$ANA_LINKS_DEF}

    brctl addif $mlc_bridge_prefix$ANA_MBR $ANA_DST_DEV
    sudo ip link set $ANA_DST_DEV up
    ip a show $mlc_bridge_prefix$ANA_MBR | grep $ANA_DST_SRC || \
	ip a add $ANA_DST_SRC dev $mlc_bridge_prefix$ANA_MBR

    for i in $(seq 1 $ANA_LINKS_MAX); do
	local lq=$( [ $i -le $links ] && echo $ANA_LQ || echo 0 )
	mlc_mac_set $ANA_MBR $((( $mlc_min_node + $i - 1 ))) $ANA_DST_DEV $ANA_DST1_MAC $lq
    done

#   mlc_mac_set $ANA_MBR 1009 $ANA_DST_DEV $ANA_DST2_MAC $ANA_LQ
#   mlc_mac_set $ANA_MBR 1009 $ANA_DST_DEV $ANA_DST2_MAC 0
}

ana_create_keys_owrt() {

    local rsaLen=${1:-"$ANA_NODE_KEY_LEN"}

    local nodeVersion="$(     ssh root@$ANA_DST1_IP4 "( bmx7 -c version || bmx7 nodeSignatureLen=$rsaLen /keyPath=/etc/bmx7/rsa.$rsaLen version ) | grep version=BMX" )"
    local nodeId="$( echo "$nodeVersion" | awk -F'id=' '{print $2}' | cut -d' ' -f1 )"; nodeId=${nodeId:-"-"}
    local nodeName="$( echo "$nodeVersion" | awk -F'hostname=' '{print $2}' | cut -d' ' -f1 )"; nodeName=${nodeName:-"-"}
    echo "nodeVersion=$nodeVersion nodId=$nodeId nodeName=$nodeName"

    ana_create_role_key_dirs $ANA_ATTACK_PEN_LEVEL
    touch $ANA_MLC_KEYS_DIR/orange-trusted-nodes/$nodeId.$nodeName

    ssh root@$ANA_DST1_IP4 "mkdir -p /$ANA_NODE_TRUSTED_DIR; rm -f /$ANA_NODE_TRUSTED_DIR/*"
    scp $ANA_MLC_KEYS_DIR/orange-trusted-nodes/* root@o101:/$ANA_NODE_TRUSTED_DIR/
}

ana_bench_tp_owrt() {
    local outFile=$1
    local duration=${2:-$ANA_MEASURE_TIME}
    local dst=${3:-$ANA_E2E_DST}

    echo "$(ana_time_stamp) tp init"
    local dst6=$( $ANA_SSH root@$ANA_E2E_SRC4 "bmx7 -c list=originators"  | grep "name=$dst" | awk -F'primaryIp=' '{print $2}' | cut -d' ' -f1 )

   $ANA_SSH root@$ANA_E2E_SRC4 "traceroute6 -n $dst6"

    local ping=$( $ANA_SSH root@$ANA_E2E_SRC4 "ping6 -nc2 $dst6" | head -n3 | tail -n1 )
    local ttl=$( echo $ping | awk -F'ttl=' '{print $2}' | cut -d' ' -f1 )
    local rtt=$( echo $ping | awk -F'time=' '{print $2}' | cut -d' ' -f1 )
    echo "$(ana_time_stamp) tp started $ANA_E2E_SRC4 -> $dst $dst6 "
    local tp=$( $ANA_SSH root@$ANA_E2E_SRC4 "iperf -V -t $duration -y C -c $dst6 | cut -d',' -f9" 2>/dev/null )
    echo "$(ana_time_stamp) tp finished"

    echo "dst6=$dst6 ttl=$ttl rtt=$rtt tp=$tp" > $outFile
    cat $outFile
}

ana_bench_top_owrt() {
    local outFile=$1
    local duration=${2:-$ANA_MEASURE_TIME}
    local delay=${3:-$ANA_PROBE_DELAY_TIME}
    local dst4=${4:-$ANA_DST1_IP4}

    echo "$(ana_time_stamp) ana_bench_top_owrt init"
    ssh root@$dst4 "sleep $delay; top -b -n2 -d $duration" > $outFile.tmp
    local mem=$(cat $outFile.tmp | grep "$ANA_PROTO_CMD" | grep -v "grep" | tail -n1 | awk '{print $5}')
    local cpu=$(cat $outFile.tmp | grep "$ANA_PROTO_CMD" | grep -v "grep" | tail -n1 | awk '{print $7}'| cut -d'%' -f1)
    local idl=$(cat $outFile.tmp | grep "CPU:" | grep -v "grep" | tail -n1 | awk '{print $8}'| cut -d'%' -f1)
    
    echo "mem=$mem cpu=$cpu idl=$idl" > $outFile
    echo "$(ana_time_stamp) ana_bench_top_owrt end:"
    cat $outFile
}

ana_bench_top_sys() {
    local outFile=$1
    local duration=${2:-$ANA_MEASURE_TIME}
    local delay=${3:-$ANA_PROBE_DELAY_TIME}


    echo "$(ana_time_stamp) ana_bench_top_sys init"
    sleep $delay
    echo "$(ana_time_stamp) ana_bench_top_sys begin"
    top -b -n2 -d $duration > $outFile.tmp
    local idl=$(cat $outFile.tmp | grep "^%Cpu" | grep -v "grep" | tail -n1 | awk '{print $8}')
    local mem=$(cat $outFile.tmp | grep "^KiB Mem" | grep -v "grep" | tail -n1 | awk '{print $7}')
    
    echo "mem=$mem idl=$idl" > $outFile
    echo "$(ana_time_stamp) ana_bench_top_sys end:"
    cat $outFile
}

ana_bench_tcp_owrt() {
    local outFile=$1
    local duration=${2:-$ANA_MEASURE_TIME}
    local delay=${3:-$ANA_PROBE_DELAY_TIME}

    echo "$(ana_time_stamp) ana_bench_tcp_owrt init"
    sleep $delay
    echo "$(ana_time_stamp) ana_bench_tcp_owrt begin"
    timeout $duration tcpdump -nve -i $ANA_DST_DEV -s 200 -w $outFile.tmp 2>/dev/null

    local rxStats=$(tshark -r $outFile.tmp -qz "io,stat,$duration,eth.src!=$ANA_DST1_MAC&&udp.port==$ANA_UDP_PORT" 2>/dev/null| tail -n2 |head -n1)
    local txStats=$(tshark -r $outFile.tmp -qz "io,stat,$duration,eth.src==$ANA_DST1_MAC&&udp.port==$ANA_UDP_PORT" 2>/dev/null| tail -n2 |head -n1)
    echo " \
       rxP=$( echo "scale=2; $(echo $rxStats | awk '{print $6}')/$duration" | bc ) \
       rxB=$( echo "scale=2; $(echo $rxStats | awk '{print $8}')/$duration" | bc ) \
       txP=$( echo "scale=2; $(echo $txStats | awk '{print $6}')/$duration" | bc ) \
       txB=$( echo "scale=2; $(echo $txStats | awk '{print $8}')/$duration" | bc ) \
       " > $outFile

     cat $outFile
    echo "$(ana_time_stamp) ana_bench_tcp_owrt end"
}

ana_bmx_stat_owrt() {
    local outFile=$1
    
    echo "$(ana_time_stamp) ana_bmx_stat_owrt begin"
    ssh root@$ANA_DST1_IP4 "bmx7 -c list=status" > $outFile
    echo "$(ana_time_stamp) ana_bmx_stat_owrt end"
}


ana_create_descUpdates_mlc() {
    
    local resultsDir=$1
    local updDuration=$2
    local updPeriod=$3
    local updRounds=$(printf "%.0f\n" $( echo "scale=2; $updDuration / $updPeriod" | bc ) )

    echo "$(ana_time_stamp) updating descriptions for $updDuration s rounds=$updRounds  period=$updPeriod s ..."

    if [ $(printf "%.0f\n" $(echo "$updPeriod * 100" | bc)) -ge 10 ]; then
	local r=

	for r in $(seq 0 $updRounds); do
	    sleep $updPeriod &
	    local n=$((( $mlc_min_node + 10 + (r % 20) )))
	    mlc_loop -i $n -e "bmx7 -c descUpdate" 
	    wait
	    [ -d $resultsDir ] || break
	done

    elif [ $(printf "%.0f\n" $(echo "$updPeriod * 100" | bc)) -le -10 ]; then
	
	ssh root@$ANA_DST1_IP4 "/tmp/$ANA_DST_BMX7_UPD $updPeriod"
	for r in $(seq 0 $(( -1 * $updRounds)) ); do
	    sleep $(( -1 * $updPeriod))
	    [ -d $resultsDir ] || break
	done
	ssh root@$ANA_DST1_IP4 "killall $ANA_DST_BMX7_UPD"
    else

	sleep $updDuration
    fi
    echo "$(ana_time_stamp) updating descriptions done"
}


ana_measure_ovhd_owrt() {

    local resultsFile=${1:-$ANA_RESULTS_FILE}
    local rtLoad=${2:-$ANA_RT_LOAD}
    local updPeriod=${3:-$ANA_UPD_PERIOD}
    local duration=${4:-$ANA_MEASURE_TIME}
    local probes=${5:-$ANA_MEASURE_PROBES}
    local probe=

    local start=$(ana_time_stamp)
    mkdir -p $(dirname $resultsFile)

    rm -rf /tmp/ana.tmp.*
    local tmpDir=$(mktemp -d /tmp/ana.tmp.XXXXXXXXXX)

    local longDuration=$((( (($duration + $ANA_PROBE_SAFE_TIME) * 2 * $probes) + $ANA_MEASURE_GAP  )))
    ana_create_descUpdates_mlc $tmpDir $longDuration $updPeriod <<< /dev/zero &

    sleep $ANA_MEASURE_GAP

    for probe in $(seq 1 $probes); do

	true && (
	    echo "$(ana_time_stamp) bench started"

	    ana_bench_top_owrt $tmpDir/topOI.out $duration 0 &
	    ana_bench_tcp_owrt $tmpDir/tcpOI.out $duration 0 &
	    ana_bench_top_sys  $tmpDir/topSI.out $duration 0 &
	    ana_bmx_stat_owrt  $tmpDir/bmxOI.out &
	    wait

	    local links="$(   cat $tmpDir/bmxOI.out | awk -F'nbs=' '{print $2}' | cut -d' ' -f1 )"

	    [ "$rtLoad" != "0" ] && [ $links -ge 3 ] && (
		ana_bench_tp_owrt  $tmpDir/tpOL.out  $((($duration + $ANA_RT_RAISE_TIME))) &
		ana_bench_tcp_owrt $tmpDir/tcpOL.out $duration $ANA_PROBE_DELAY_TIME &
		ana_bench_top_sys  $tmpDir/topSL.out $duration $ANA_PROBE_DELAY_TIME &
		wait
	    )
	    echo "$(ana_time_stamp) bench finished"
	)

	echo "$(ana_time_stamp) summarizing probe=$probe results from $tmpDir"

	local links="$(   cat $tmpDir/bmxOI.out | awk -F'nbs=' '{print $2}' | cut -d' ' -f1 )"
	local nodes="$(   cat $tmpDir/bmxOI.out | awk -F'nodes=' '{print $2}' | cut -d'/' -f1 )"
	local bmxCpu="$(  cat $tmpDir/bmxOI.out | awk -F'cpu=' '{print $2}' | cut -d' ' -f1 )"
	local txPps="$(   cat $tmpDir/bmxOI.out | awk -F'txBpP=' '{print $2}' | cut -d' ' -f1 | cut -d '/' -f2)"
	local txBps="$(   cat $tmpDir/bmxOI.out | awk -F'txBpP=' '{print $2}' | cut -d' ' -f1 | cut -d '/' -f1)"
	local rxPps="$(   cat $tmpDir/bmxOI.out | awk -F'rxBpP=' '{print $2}' | cut -d' ' -f1 | cut -d '/' -f2)"
	local rxBps="$(   cat $tmpDir/bmxOI.out | awk -F'rxBpP=' '{print $2}' | cut -d' ' -f1 | cut -d '/' -f1)"
	local linkRsa="$( cat $tmpDir/bmxOI.out | awk -F'linkKey=RSA' '{print $2}' | cut -d' ' -f1 )"
	local nodeRsa="$( cat $tmpDir/bmxOI.out | awk -F'nodeKey=RSA' '{print $2}' | cut -d' ' -f1 )"
	local rev="$(     cat $tmpDir/bmxOI.out | awk -F'revision=' '{print $2}' | cut -d' ' -f1 )"
	local txq="$( echo "scale=2; $( cat $tmpDir/bmxOI.out | awk -F'txQ=' '{print $2}' | cut -d' ' -f1)" | bc) "
	local lstDsc="$(  cat $tmpDir/bmxOI.out | awk -F'lastDesc=' '{print $2}' | cut -d' ' -f1 )"
	local uptime="$(  cat $tmpDir/bmxOI.out | awk -F'uptime=' '{print $2}' | cut -d' ' -f1 )"


	local mmOI=$(cat $tmpDir/topOI.out | awk -F'mem=' '{print $2}'| cut -d' ' -f1)
	local cpOI=$(cat $tmpDir/topOI.out | awk -F'cpu=' '{print $2}'| cut -d' ' -f1)
	local idOI=$(cat $tmpDir/topOI.out | awk -F'idl=' '{print $2}'| cut -d' ' -f1)
	local txPI=$(cat $tmpDir/tcpOI.out | awk -F'txP=' '{print $2}'| cut -d' ' -f1)
	local txBI=$(cat $tmpDir/tcpOI.out | awk -F'txB=' '{print $2}'| cut -d' ' -f1)
	local rxPI=$(cat $tmpDir/tcpOI.out | awk -F'rxP=' '{print $2}'| cut -d' ' -f1)
	local rxBI=$(cat $tmpDir/tcpOI.out | awk -F'rxB=' '{print $2}'| cut -d' ' -f1)
	local idSI=$(cat $tmpDir/topSI.out | awk -F'idl=' '{print $2}'| cut -d' ' -f1)

	local tpOL=$(cat $tmpDir/tpOL.out  | awk -F'tp='  '{print $2}'| cut -d' ' -f1)
	local rttL=$(cat $tmpDir/tpOL.out  | awk -F'rtt=' '{print $2}'| cut -d' ' -f1)
	local ttlL=$(cat $tmpDir/tpOL.out  | awk -F'ttl=' '{print $2}'| cut -d' ' -f1)
	local txPL=$(cat $tmpDir/tcpOL.out | awk -F'txP=' '{print $2}'| cut -d' ' -f1)
	local txBL=$(cat $tmpDir/tcpOL.out | awk -F'txB=' '{print $2}'| cut -d' ' -f1)
	local rxPL=$(cat $tmpDir/tcpOL.out | awk -F'rxP=' '{print $2}'| cut -d' ' -f1)
	local rxBL=$(cat $tmpDir/tcpOL.out | awk -F'rxB=' '{print $2}'| cut -d' ' -f1)
	local idSL=$(cat $tmpDir/topSL.out | awk -F'idl=' '{print $2}'| cut -d' ' -f1)

	FORMAT="%16s %16s %8s %5s %9s   %6s %6s %10s %11s %9s   %5s %10s %6s %3s   %4s %4s %6s %4s %4s %4s   %8s %8s %8s %8s  %8s %8s %8s %8s   %11s %6s" 
	FIELDS="start end duration probe revision  Links Nodes linkRsa nodeRsa updPeriod  txq tp rtt ttl  CPU BCPU Memory idOI idSI idSL  outPps txPL outBps txBL inPps rxPL inBps rxBL  uptime lstDsc"
	printf "$FORMAT \n" $FIELDS
	[ -f $resultsFile ] || printf "$FORMAT \n" $FIELDS > $resultsFile
	printf "$FORMAT \n" \
	    $start $(ana_time_stamp) ${duration:-"NA"} $probe ${rev:-"NA"} \
	    ${links:-"NA"} ${nodes:-"NA"}  ${linkRsa:-"NA"} ${nodeRsa:-"NA"} ${updPeriod:-"NA"}  \
	    ${txq:-"NA"} ${tpOL:-"NA"} ${rttL:-"NA"} ${ttlL:-"NA"} \
	    ${cpOI:-"NA"} ${bmxCpu:-"NA"} ${mmOI:-"NA"} ${idOI:-"NA"} ${idSI:-"NA"} ${idSL:-"NA"} \
	    ${txPI:-"NA"} ${txPL:-"NA"} ${txBI:-"NA"} ${txBL:-"NA"} ${rxPI:-"NA"} ${rxPL:-"NA"} ${rxBI:-"NA"} ${rxBL:-"NA"} \
	    ${uptime:-"NA"} ${lstDsc:-"NA"} \
	    | tee -a $resultsFile

    done

    rm -r $tmpDir
    echo "$(ana_time_stamp) waiting for finished descUpdates ... "
    wait
    echo "$(ana_time_stamp) done"

}



ana_fetch_node_role() {

    local anaId=${1:-$mlc_min_node}
    local penLevel=${2:-$ANA_ATTACK_PEN_LEVEL}
    local rsaLen=${3:-"$ANA_NODE_KEY_LEN"}

    local anaIp="$(MLC_calc_ip4 $mlc_ip4_admin_prefix1 $anaId $mlc_admin_idx )"
    local nodeName="${mlc_name_prefix}${anaId}"
    local nodeVersion="$( $mlc_ssh root@$anaIp "( bmx7 -c version || bmx7 nodeSignatureLen=$rsaLen /keyPath=/etc/bmx7/rsa.$rsaLen version ) | grep version=BMX" )"
    local nodeId="$( echo "$nodeVersion" | awk -F'id=' '{print $2}' | cut -d' ' -f1 )"; nodeId=${nodeId:-"-"}
    local nodeIp="$( echo "$nodeVersion" | awk -F'ip=' '{print $2}' | cut -d' ' -f1 )"; nodeIp=${nodeIp:-"-"}

    local topoColsPerRole=$((( $ANA_ATTACK_TOPO_COLS / $ANA_ATTACK_TOPO_ROLES )))
    local nodeIdx=$((( $anaId - $mlc_min_node )))
    local nodeCol=$((( $nodeIdx % $ANA_ATTACK_TOPO_COLS )))
    local nodeLine=$((( $nodeIdx / $ANA_ATTACK_TOPO_COLS )))
    local topoLines=$((( $ANA_NODES_MAX / $ANA_ATTACK_TOPO_COLS )))
    local topoLineTop=0
    local topoLineBottom=$((( $topoLines - 1 )))
    local nodeRoleLMin=$((( $nodeCol / $topoColsPerRole )))
    local nodeRoleLMax=$nodeRoleLMin
    local nodeRole=$nodeRoleLMin
    local rolePenetrationLines=$((( ($topoLines-2) / $ANA_ATTACK_TOPO_ROLES )))


    if [ $nodeLine -gt $topoLineTop ] && [ $nodeLine -lt  $topoLineBottom ]; then

	nodeRoleLMax=$((( ( $nodeLine - 1 ) / $rolePenetrationLines )))

	local leftL0ColBound=$((( $nodeRoleLMax * $topoColsPerRole )))
	local leftLxColBound=$((( $leftL0ColBound - $penLevel )))
	local rightL0ColBound=$((( $leftL0ColBound + $topoColsPerRole - 1 )))
	local rightLxColBound=$((( $rightL0ColBound + $penLevel )))

	local fixedNodeCol=$nodeCol

	if [ $leftLxColBound -lt 0 ] && [ $nodeCol -ge $((( $ANA_ATTACK_TOPO_COLS - $penLevel ))) ]; then
	    fixedNodeCol=$((( $nodeCol - $ANA_ATTACK_TOPO_COLS )))
	fi
	
	if [ $rightLxColBound -ge $ANA_ATTACK_TOPO_COLS ] && [ $nodeCol -le $((( $penLevel - 1 ))) ]; then
	    fixedNodeCol=$((( $nodeCol + $ANA_ATTACK_TOPO_COLS )))
	fi

	if [ $fixedNodeCol -ge $leftLxColBound ] && [ $fixedNodeCol -le $rightLxColBound ]; then
	    nodeRole=$nodeRoleLMax
	fi

    fi


   [ $nodeIdx -eq 0 ] &&\
    printf "$ANA_ROLE_FILE_FORMAT" $ANA_ROLE_FILE_HEADER >&2
    printf "$ANA_ROLE_FILE_FORMAT" $ANA_ATTACK_TOPO_COLS $ANA_NODES_MAX $penLevel $anaId $anaIp $nodeName $nodeId $nodeIp $nodeCol $nodeLine $nodeRoleLMin $nodeRoleLMax $nodeRole ${ANA_ATTACK_ROLE_COLORS[$nodeRole]}
}

ana_fetch_role() {

    local penLevel=${1:-$ANA_ATTACK_PEN_LEVEL}
    local rsaLen=${2:-"$ANA_NODE_KEY_LEN"}
    local roleFile="$ANA_ATTACK_OF_DIR/$ANA_ATTACK_OF_PREFIX-$penLevel"

    local i=

    mkdir -p $ANA_ATTACK_OF_DIR
    rm -f $roleFile

    for i in $(seq $mlc_min_node $ANA_NODE_MAX); do
	
	local line="$(ana_fetch_node_role $i $penLevel $rsaLen )"
	echo "$line" >> $roleFile 
	echo "$line"
	printf "%d" $(echo "$line" | awk '{print $13}')

	[ $((( ($i + 1 - $mlc_min_node) % $ANA_ATTACK_TOPO_COLS ))) -eq 0 ] && echo

    done
    echo
}

ana_fetch_roles() {
    local penLevels=${1:-"$((( $ANA_ATTACK_TOPO_COLS / $ANA_ATTACK_TOPO_ROLES )))"}
    local rsaLen=${2:-"$ANA_NODE_KEY_LEN"}
    local i=

    for i in $(seq 0 $penLevels); do
	ana_fetch_role $i $rsaLen
    done

}

ana_create_role_dir_links() {

    local penLevel=${1:-$ANA_ATTACK_PEN_LEVEL}
    local roleFile="$ANA_ATTACK_OF_DIR/$ANA_ATTACK_OF_PREFIX-$penLevel"
    local subjectLine=

    rm -rf $ANA_MLC_DIR/rootfs/mlc1*/rootfs/$ANA_NODE_TRUSTED_DIR
    rm -rf $ANA_MLC_DIR/rootfs/mlc1*/rootfs/$ANA_NODE_ATTACKED_DIR

    
    while read -r subjectLine; do
	local subjectLineArray=($subjectLine)
	
	local subjectMlcId=${subjectLineArray[$ANA_ROLE_FILE_COL_MLCID]}
	local subjectName=${subjectLineArray[$ANA_ROLE_FILE_COL_NAME]}
	local subjectRole=${subjectLineArray[$ANA_ROLE_FILE_COL_NODEROLE]}
	local subjectRoleColor=${ANA_ATTACK_ROLE_COLORS[$subjectRole]}

	echo "checking: subjectRole=$subjectRoleColor subject: mlcId=$subjectMlcId name=$subjectName role=$subjectRole"
	
	if [ $subjectMlcId -le $ANA_NODE_MAX ]; then
	    ln -s /$ANA_NODE_KEYS_DIR/$subjectRoleColor-trusted-nodes   $ANA_MLC_DIR/rootfs/$subjectName/rootfs/$ANA_NODE_TRUSTED_DIR
	    ln -s /$ANA_NODE_KEYS_DIR/$subjectRoleColor-attacked-nodes  $ANA_MLC_DIR/rootfs/$subjectName/rootfs/$ANA_NODE_ATTACKED_DIR
	fi
    done < $roleFile
}

ana_get_role_behavior() {
    declare -a argTable=("${!1}")
    local line_subjectRole=$2
    local col_objectRole=$3

    local item=$((( $line_subjectRole * $ANA_ATTACK_TOPO_ROLES + $col_objectRole )))
    
    [ "${argTable[$item]}"  = "1" ] &&  true ||  false 
}

ana_test_get_role_behavior() {

    local c=
    local l=

    for c in $(seq 0 2); do
	for l in $(seq 0 2); do
	    printf "%d" $( ana_get_role_behavior ANA_TRUST_TABLE[@] $l $c && echo 1 || echo 0 )
	done
	echo
    done

   [ "$1"  = "1" ] &&  true ||  false 
}


ana_create_role_key_dirs() {

    local penLevel=${1:-$ANA_ATTACK_PEN_LEVEL}
    local roleFile="$ANA_ATTACK_OF_DIR/$ANA_ATTACK_OF_PREFIX-$penLevel"
    local subjectRole=
    local objectLine=

    for subjectRole in $(seq 0 $((( $ANA_ATTACK_TOPO_ROLES - 1))) ); do
	local subjectRoleColor=${ANA_ATTACK_ROLE_COLORS[$subjectRole]}
	local trustedNodesDir="$ANA_MLC_KEYS_DIR/$subjectRoleColor-trusted-nodes"
	local attackedNodesDir="$ANA_MLC_KEYS_DIR/$subjectRoleColor-attacked-nodes"

	mkdir -p $trustedNodesDir
	rm -f $trustedNodesDir/*
	mkdir -p $attackedNodesDir
	rm -f $attackedNodesDir/*

	while read -r objectLine; do
	    local objectLineArray=($objectLine)
	    
	    local objectMlcId=${objectLineArray[$ANA_ROLE_FILE_COL_MLCID]}
	    local objectName=${objectLineArray[$ANA_ROLE_FILE_COL_NAME]}
	    local objectRole=${objectLineArray[$ANA_ROLE_FILE_COL_NODEROLE]}
	    local objectKey=${objectLineArray[$ANA_ROLE_FILE_COL_NODEID]}

	    echo "checking: subjectRole=$subjectRoleColor object: mlcId=$objectMlcId name=$objectName role=$objectRole key=$objectKey"
	    
	    if [ $objectMlcId -le $ANA_NODE_MAX ]; then
		ana_get_role_behavior ANA_TRUST_TABLE[@]  $subjectRole $objectRole && touch $trustedNodesDir/$objectKey.$objectName
		ana_get_role_behavior ANA_ATTACK_TABLE[@] $subjectRole $objectRole && touch $attackedNodesDir/$objectKey.$objectName
	    fi
	done < $roleFile

    done 

    ana_create_role_dir_links $penLevel
}


ana_init_ovhd_scenarios() {

    killall -w $ANA_PROTO

    ./mlc-init-host.sh
    
    ana_create_nodes
    ana_create_net_owrt
    ana_create_links_owrt
    ana_create_protos 0
    ana_update_dst
    ana_update_mlc
    ana_fetch_roles 0
    ana_create_keys_owrt
}

ana_set_protos_owrt() {
    local nodes=${1:-$ANA_NODES_DEF}
    local param="${2:-"date"}"

    ssh root@$ANA_DST1_IP4 "$param"
    mlc_loop -la $((( $mlc_min_node + $nodes - 1 ))) -e "$param"
}

ana_run_ovhd_scenarios() {

    ana_init_ovhd_scenarios

    local params=
    local p=
    local results=
    local round=

    for round in $(seq 1 $ANA_MEASURE_ROUNDS); do

	if true; then
	    params="512 768 896 1024 1536 2048 3072 4096"
	    results="$(dirname $ANA_RESULTS_FILE)/$(ana_time_stamp)-ovhdVsIdCrypt"
	    ana_create_links_owrt
	    for p in $params; do
		ana_create_protos 0
		ana_fetch_roles 0 $p
		ana_create_keys_owrt $p
		ana_create_protos $ANA_NODES_DEF $p 
		echo "$(ana_time_stamp) MEASURING to $results p=$p of $params"
		sleep $ANA_STABILIZE_TIME
		ana_measure_ovhd_owrt $results $ANA_RT_LOAD
	    done
	    ana_create_protos 0
	    ana_fetch_roles 0
	    ana_create_keys_owrt
	fi

	if true; then
	    params="30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200"
	    results="$(dirname $ANA_RESULTS_FILE)/$(ana_time_stamp)-ovhdVsNodes"
	    ana_create_protos 0
	    ana_create_links_owrt
	    for p in $params; do
		ana_create_protos $p
		echo "$(ana_time_stamp) MEASURING to $results p=$p of $params"
		sleep $ANA_STABILIZE_TIME
		ana_measure_ovhd_owrt $results $ANA_RT_LOAD
	    done
	fi

	if true; then
	    params="4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"
	    results="$(dirname $ANA_RESULTS_FILE)/$(ana_time_stamp)-ovhdVsLinks"
	    ana_create_protos 0
	    ana_create_links_owrt 0
	    ana_create_protos
	    for p in $params; do
		ana_create_links_owrt $p
		echo "$(ana_time_stamp) MEASURING to $results p=$p of $params"
		sleep $ANA_STABILIZE_TIME
		ana_measure_ovhd_owrt $results $ANA_RT_LOAD
	    done
	fi

	if true; then
	    params="30 20 15 10 7 5 3 2 1 0.7 0.5 0.4 0.3 0.2"
	    results="$(dirname $ANA_RESULTS_FILE)/$(ana_time_stamp)-ovhdVsUpdates"
	    ana_create_protos 0
	    ana_create_links_owrt
	    ana_create_protos
	    sleep $ANA_STABILIZE_TIME
	    for p in $params; do
		echo "$(ana_time_stamp) MEASURING to $results p=$p of $params"
		ana_measure_ovhd_owrt $results $ANA_RT_LOAD $p
	    done
	fi

	if true; then
	    params="-15 -10 -5 -3 -2"
	    results="$(dirname $ANA_RESULTS_FILE)/$(ana_time_stamp)-ovhdVsOwnUpdates"
	    ana_create_protos 0
	    ana_create_links_owrt
	    ana_create_protos
	    sleep $ANA_STABILIZE_TIME
	    for p in $params; do
		echo "$(ana_time_stamp) MEASURING to $results p=$p of $params"
		ana_measure_ovhd_owrt $results $ANA_RT_LOAD $p
	    done
	fi

	if true; then
	    params="512 768 896 1024 1536"
	    results="$(dirname $ANA_RESULTS_FILE)/$(ana_time_stamp)-ovhdVsTxCrypt"
	    ana_create_protos 0
	    ana_create_links_owrt
	    ana_create_protos
	    for p in $params; do
		ana_set_protos_owrt $ANA_LINKS_DEF "bmx7 -c linkSignatureLen=$p"
		echo "$(ana_time_stamp) MEASURING to $results p=$p of $params"
		sleep $ANA_STABILIZE_TIME
		ana_measure_ovhd_owrt $results $ANA_RT_LOAD
	    done
	fi


    done
}



ana_enable_trust() {
   local nodeId=${1:-"$ANA_CPA_TRUST_NODES"}
   local id=
   for id in $nodeId; do
       mlc_loop -i $id -e "bmx7 -c trustedNodesDir=/etc/bmx7/trustedNodes"
   done
}

ana_disable_trust() {
   local nodeId=${1:-"$ANA_CPA_TRUST_NODES"}
   local id=
   for id in $nodeId; do
       mlc_loop -i $id -e "bmx7 -c trustedNodesDir=-"
   done
}

ana_enable_cpa_attack() {
   local nodeId=${1:-"$ANA_CPA_ATTACK_NODE"}
   mlc_loop -i $nodeId -e "bmx7 -c evilOgmSqns=1" 
}

ana_disable_cpa_attack() {
   local nodeId=${1:-"$ANA_CPA_ATTACK_NODE"}
   mlc_loop -i $nodeId -e "bmx7 -c evilOgmSqns=-" 
}


ana_measure_e2e_route() {

    local srcNodeId=${1}
    local dstNodeId=${2}
    local penLevel=${3:-"$ANA_ATTACK_PEN_LEVEL"}
    
    local roleFile="$ANA_ATTACK_OF_DIR/$ANA_ATTACK_OF_PREFIX-$penLevel"
    local objectLine=
    local srcMlcIp=
    local dstNodeIp=

    while read -r objectLine; do
	local objectLineArray=($objectLine)
	local objectMlcId=${objectLineArray[$ANA_ROLE_FILE_COL_MLCID]}
	local objectMlcIp=${objectLineArray[$ANA_ROLE_FILE_COL_MLCIP]}
	local objectNodeIp=${objectLineArray[$ANA_ROLE_FILE_COL_NODEIP]}
	
	if [ $objectMlcId -eq $srcNodeId ]; then
	    srcMlcIp=$objectMlcIp
	fi
	if [ $objectMlcId -eq $dstNodeId ]; then
	    dstNodeIp=$objectNodeIp
	fi
    done < $roleFile

    echo "-------------------------------------------" >&2
    echo "srcMlcIp=$srcMlcIp dstNodeIp=$dstNodeIp ..." >&2

    local rtt=$( \
	[ "$srcMlcIp" ] && [ "$dstNodeIp" ] && \
	echo "$($ANA_SSH root@$srcMlcIp "time ping6 -n -i 0.1 -c1 -w $ANA_PING_DEADLINE $dstNodeIp " 2>&1 | grep -e '^real' | grep -e '0m' | cut -d'm' -f2 | cut -d's' -f1 ) * 1000" | bc  -l | cut -d'.' -f1 )
    
    [ "$rtt" ] && [ $rtt -le $((( 1000 * ( $ANA_PING_DEADLINE - 1)))) ] && echo $rtt || echo NA 
}





ana_init_security_scenarios() {

    ./mlc-init-host.sh

    ana_create_nodes

    ana_create_protos_mlc 0

    ana_fetch_roles

}

ana_configure_grid() {

    local lq=${2:-"$ANA_LQ"}

    mlc_net_flush
#   mlc_configure_grid <dev_idx> [lq] [loop_x_lq] [loop_y_lq] [0=ortographic,1=diagonal] [distance] [max_node]    [min_node]    [rq] [loop_x_rq] [loop_y_rq] [columns]             [purge]
    mlc_configure_grid $ANA_MBR  $lq  $lq         0           0                          1          $ANA_NODE_MAX $mlc_min_node $lq  $lq         0           $ANA_ATTACK_TOPO_COLS 1
}



ana_measure_e2e_recovery() {

    local lq=${1:-$ANA_LQ}
    local penLevel=${2:-$ANA_ATTACK_PEN_LEVEL}
    local srcNodeId=${3}
    local dstNodeId=${4}

    local resultsDir=$ANA_RESULTS_DIR
    local resultsFile=$ANA_RESULTS_FILE_PREFIX

    mkdir -p $resultsDir
    touch $resultsDir/$resultsFile

    ana_disable_trust $dstNodeId
    ana_enable_cpa_attack $ANA_CPA_ATTACK_NODE
    sleep $ANA_STABILIZE_TIME
    ana_enable_trust $dstNodeId &

    local recoveryLatency=$( ana_measure_e2e_route $srcNodeId $dstNodeId )

    echo   "date nodes cols roles penLevel stabTime srcId dstId cpaId latency ttl rtt ovhd sysCpu srcNodeMem dstNodeMem"
    printf "%20  " \
	$(ana_time_stamp) \
	$ANA_NODES_MAX \
	$ANA_ATTACK_TOPO_COLS \
	$ANA_ATTACK_TOPO_ROLES \
	$penLevel \
	$ANA_STABILIZE_TIME \
	$srcNodeId \
	$dstNodeId \
	$ANA_CPA_ATTACK_NODE \
	$recoveryLatency \
	\
	>> $resultsDir/$resultsFile
}


ana_run_security_scenarios() {

    local lq=${1:-$ANA_LQ}
    local penLevel=${2:-$ANA_ATTACK_PEN_LEVEL}


    ana_create_protos_mlc 0
    ana_create_role_key_dirs $penLevel
    ana_create_protos_mlc 0
    ana_create_protos_mlc $ANA_NODES_MAX

    local srcDstId=
    for srcDstId in $ANA_NODE_PROBE_PAIRS; do
	local srcId=$( echo $srcDstId | cut -d':' -f1 )
	local dstId=$( echo $srcDstId | cut -d':' -f2 )
	
	local results=$( ana_measure_e2e_recovery $lq $penLevel $srcId $dstId )
    done

}

ana_all() {

    local lq=${1:-$ANA_LQ}
    local penLevels=$((( $ANA_ATTACK_TOPO_COLS / $ANA_ATTACK_TOPO_ROLES )))
    local i=

#    ana_init_security_scenarios

    ana_configure_grid $ANA_NODE_MAX $lq $ANA_ATTACK_TOPO_COLS

    for i in $(seq 0 $penLevels); do
	echo ana_run_security_scenarios $lq $i
    done
}

################################
# misc...


ana_create_random_set() {

    local NUM=${1:-50}
    local FROM=${2:-100}

    local IN="$(seq 0 $(($FROM-1)) )"
    local OUT=

    for i in $(seq 1 $NUM); do
#	echo "IN=$IN"
	
	local R=$(./ana_rand.sh 1 $(($FROM+1-$i)) )
#	echo "COL=$R"

	local VAL=$(echo "$IN" | sed -n ${R}p )
#	echo "VAL=$VAL"
	
	if [ "$OUT" ]; then
	    OUT="$OUT $VAL"
	else
	    OUT="$VAL"
	fi
#	echo "OUT=$OUT"

	IN="$(echo "$IN" | sed  "${R}d" )"

    done
    
    echo "$OUT"
}

ana_create_random_keys() {
    local NUM=${1:-50}
    local FROM=${1:-$ANA_NODES_DEF}

    local keysPath=$ANA_MLC_KEYS_DIR/

    local keysSortedAll="$(for f in $(ls -l $keysPath/ | grep -o -e "mlc...." -e "o101" | sort); do (cd $keysPath && ls *.$f); done)"
    
    local keysSortedFrom="$(echo "$keysSortedAll" | head -n $FROM)"

    for i in $(seq 1 $NUM); do
	let from=$FROM+1-$i

	pickId=$(./ana_rand 1 $from )
    done


}