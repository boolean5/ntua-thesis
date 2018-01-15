#!/bin/bash


# ssh variables
USER_1=ubuntu
USER_2=ubuntu
USER_3=ubuntu
CLIENT=ubuntu
SERVER_IP_1=ec2-34-252-177-227.eu-west-1.compute.amazonaws.com
SERVER_IP_2=ec2-34-253-143-235.eu-west-1.compute.amazonaws.com
SERVER_IP_3=ec2-54-77-159-220.eu-west-1.compute.amazonaws.com
CLIENT_IP=ec2-54-77-43-242.eu-west-1.compute.amazonaws.com

HOST_1=172.31.17.126
HOST_2=172.31.21.43
HOST_3=172.31.16.202

# KEY_PATH="~/Desktop/Link\ to\ DIPLOMA/official_benchmarks/id_rsa.pem"
KEY_PATH="../../id_rsa.pem"

# etcdctl & benchmark variables
export ETCDCTL_API=3
ENDPOINTS=http://${HOST_1}:2379,http://${HOST_2}:2379,http://${HOST_3}:2379

# cluster bootstrapping variables
TOKEN=token-01
CLUSTER_STATE=new
NAME_1=etcd-1
NAME_2=etcd-2
NAME_3=etcd-3
CLUSTER=${NAME_1}=http://${HOST_1}:2380,${NAME_2}=http://${HOST_2}:2380,${NAME_3}=http://${HOST_3}:2380


BIN_PATH=/home/ubuntu/go/src/github.com/boolean5/etcd/bin/

ETCD_1_COMMAND="etcd --data-dir /mnt/etcd/data.etcd/ --name ${NAME_1} --initial-advertise-peer-urls http://${HOST_1}:2380 --listen-peer-urls http://${HOST_1}:2380 --advertise-client-urls http://${HOST_1}:2379 --listen-client-urls http://${HOST_1}:2379 --initial-cluster ${CLUSTER} --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}"
ETCD_2_COMMAND="etcd --data-dir /mnt/etcd/data.etcd/ --name ${NAME_2} --initial-advertise-peer-urls http://${HOST_2}:2380 --listen-peer-urls http://${HOST_2}:2380 --advertise-client-urls http://${HOST_2}:2379 --listen-client-urls http://${HOST_2}:2379 --initial-cluster ${CLUSTER} --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}"
ETCD_3_COMMAND="etcd --data-dir /mnt/etcd/data.etcd/ --name ${NAME_3} --initial-advertise-peer-urls http://${HOST_3}:2380 --listen-peer-urls http://${HOST_3}:2380 --advertise-client-urls http://${HOST_3}:2379 --listen-client-urls http://${HOST_3}:2379 --initial-cluster ${CLUSTER} --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}"

OUTPUT_FILE=results.txt

TEST_COMMAND="etcdctl --endpoints=${ENDPOINTS} put foo OK"

FILL="benchmark --endpoints=${ENDPOINTS} --conns=100 --clients=1000 put --key-size=8 --sequential-keys=false --key-space-size=100000 --total=100000 --val-size=256"

function bench3rounds {
        for i in `seq 1 3`;
        do
                echo "----------------- round $i -----------------" >> ${OUTPUT_FILE}

                ssh -i ${KEY_PATH} ${USER_1}@${SERVER_IP_1} "sudo ${BIN_PATH}${ETCD_1_COMMAND}" &
                ssh -i ${KEY_PATH} ${USER_2}@${SERVER_IP_2} "sudo ${BIN_PATH}${ETCD_2_COMMAND}" &
                ssh -i ${KEY_PATH} ${USER_3}@${SERVER_IP_3} "sudo ${BIN_PATH}${ETCD_3_COMMAND}" &

                echo "Starting etcd cluster..." >> ${OUTPUT_FILE}

                sleep 10s
                OK=`ssh -i ${KEY_PATH} ${CLIENT}@${CLIENT_IP} "export ETCDCTL_API=3; ${BIN_PATH}$2"`
                if [[ $OK != 'OK' ]] || [[ -z "$OK" ]]
                 then
                        sleep 10s
                        OK=`ssh -i ${KEY_PATH} ${CLIENT}@${CLIENT_IP} "export ETCDCTL_API=3; ${BIN_PATH}$2"`
                        if [[ $OK != 'OK' ]] || [[ -z "$OK" ]]
                         then
                                echo "Error bootstraping cluster. Terminating" >> ${OUTPUT_FILE}
                                exit
                        fi
                fi

                echo "Cluster started." >> ${OUTPUT_FILE}

                ssh -i ${KEY_PATH} ${CLIENT}@${CLIENT_IP} "${BIN_PATH}$1" >> ${OUTPUT_FILE}

                echo "Benchmark completed. Destroying cluster and cleaning data-dirs" >> ${OUTPUT_FILE}
                ssh -i ${KEY_PATH} ${USER_1}@${SERVER_IP_1} "kill \`pidof etcd\`; sudo rm -r /mnt/etcd/data.etcd"
                ssh -i ${KEY_PATH} ${USER_2}@${SERVER_IP_2} "kill \`pidof etcd\`; sudo rm -r /mnt/etcd/data.etcd"
                ssh -i ${KEY_PATH} ${USER_3}@${SERVER_IP_3} "kill \`pidof etcd\`; sudo rm -r /mnt/etcd/data.etcd"

                sleep 10s
        done
}


function bench3roundsfilled {
        for i in `seq 1 3`;
        do
                echo "----------------- round $i -----------------" >> ${OUTPUT_FILE}

                ssh -i ${KEY_PATH} ${USER_1}@${SERVER_IP_1} "sudo ${BIN_PATH}${ETCD_1_COMMAND}" &
                ssh -i ${KEY_PATH} ${USER_2}@${SERVER_IP_2} "sudo ${BIN_PATH}${ETCD_2_COMMAND}" &
                ssh -i ${KEY_PATH} ${USER_3}@${SERVER_IP_3} "sudo ${BIN_PATH}${ETCD_3_COMMAND}" &

                echo "Starting etcd cluster..." >> ${OUTPUT_FILE}

                sleep 10s
                OK=`ssh -i ${KEY_PATH} ${CLIENT}@${CLIENT_IP} "export ETCDCTL_API=3; ${BIN_PATH}$2"`
                if [[ $OK != 'OK' ]] || [[ -z "$OK" ]]
                 then
                        sleep 10s
                        OK=`ssh -i ${KEY_PATH} ${CLIENT}@${CLIENT_IP} "export ETCDCTL_API=3; ${BIN_PATH}$2"`
                        if [[ $OK != 'OK' ]] || [[ -z "$OK" ]]
                         then
                                echo "Error bootstraping cluster. Terminating" >> ${OUTPUT_FILE}
                                exit
                        fi
                fi

                echo "Cluster started." >> ${OUTPUT_FILE}

                echo "Filling up the store..." >> ${OUTPUT_FILE}
                ssh -i ${KEY_PATH} ${CLIENT}@${CLIENT_IP} "${BIN_PATH}${FILL}"
                ssh -i ${KEY_PATH} ${CLIENT}@${CLIENT_IP} "export ETCDCTL_API=3; ${BIN_PATH}etcdctl put a s; ${BIN_PATH}etcdctl put b s; ${BIN_PATH}etcdctl put c s; ${BIN_PATH}etcdctl put d s; ${BIN_PATH}etcdctl put e s; ${BIN_PATH}etcdctl put f s; ${BIN_PATH}etcdctl put g s; ${BIN_PATH}etcdctl put h s; ${BIN_PATH}etcdctl put i s; ${BIN_PATH}etcdctl put j s; ${BIN_PATH}etcdctl put k s; ${BIN_PATH}etcdctl put l s; ${BIN_PATH}etcdctl put m s; ${BIN_PATH}etcdctl put n s; ${BIN_PATH}etcdctl put o s; ${BIN_PATH}etcdctl put p s; ${BIN_PATH}etcdctl put q s; ${BIN_PATH}etcdctl put r s; ${BIN_PATH}etcdctl put s s; ${BIN_PATH}etcdctl put t s; ${BIN_PATH}etcdctl put u s; ${BIN_PATH}etcdctl put v s; ${BIN_PATH}etcdctl put w s; ${BIN_PATH}etcdctl put x s; ${BIN_PATH}etcdctl put y s; ${BIN_PATH}etcdctl put z s;"

                echo "Done filling up the store." >> ${OUTPUT_FILE}

                ssh -i ${KEY_PATH} ${CLIENT}@${CLIENT_IP} "${BIN_PATH}$1" >> ${OUTPUT_FILE}

                echo "Benchmark completed. Destroying cluster and cleaning data-dirs" >> ${OUTPUT_FILE}

                ssh -i ${KEY_PATH} ${USER_1}@${SERVER_IP_1} "kill `pidof etcd`"; "sudo rm -r /mnt/etcd/data.etcd"
                ssh -i ${KEY_PATH} ${USER_2}@${SERVER_IP_2} "kill `pidof etcd`"; "sudo rm -r /mnt/etcd/data.etcd"
                ssh -i ${KEY_PATH} ${USER_3}@${SERVER_IP_3} "kill `pidof etcd`"; "sudo rm -r /mnt/etcd/data.etcd"

                sleep 10s
        done
}


echo "*********************** benchmark B7 **********************" >> ${OUTPUT_FILE}
BENCH_COMMAND="benchmark --endpoints=${ENDPOINTS} --conns=100 --clients=100 put --key-size=8 --sequential-keys=false --key-space-size=100000 --total=100000 --val-size=256"
bench3rounds "$BENCH_COMMAND" "$TEST_COMMAND"

echo "*********************** benchmark B8 **********************" >> ${OUTPUT_FILE}
BENCH_COMMAND="benchmark --endpoints=${ENDPOINTS} --conns=100 --clients=1000 put --key-size=8 --sequential-keys=false --key-space-size=100000 --total=100000 --val-size=256"
bench3rounds "$BENCH_COMMAND" "$TEST_COMMAND"
echo "*********************** benchmark B9 **********************" >> ${OUTPUT_FILE}
BENCH_COMMAND="benchmark --endpoints=${ENDPOINTS} --conns=100 --clients=1000 put --key-size=8 --sequential-keys=false --key-space-size=1000000 --total=1000000 --val-size=256"
# take a disk size measurement with du -sh db
bench3rounds "$BENCH_COMMAND" "$TEST_COMMAND"

echo "*********************** benchmark B19 **********************" >> ${OUTPUT_FILE}
BENCH_COMMAND="benchmark --endpoints=${ENDPOINTS} --conns=100 --clients=100 range a --consistency=l --total=100000"
bench3roundsfilled "$BENCH_COMMAND" "$TEST_COMMAND"

echo "*********************** benchmark B20 **********************" >> ${OUTPUT_FILE}
BENCH_COMMAND="benchmark --endpoints=${ENDPOINTS} --conns=100 --clients=1000 range a --consistency=l --total=100000"
bench3roundsfilled "$BENCH_COMMAND" "$TEST_COMMAND"

echo "*********************** benchmark B21 **********************" >> ${OUTPUT_FILE}
BENCH_COMMAND="benchmark --endpoints=${ENDPOINTS} --conns=100 --clients=1000 range a --consistency=l --total=1000000"
bench3roundsfilled "$BENCH_COMMAND" "$TEST_COMMAND"

echo "*********************** benchmark B22 **********************" >> ${OUTPUT_FILE}
BENCH_COMMAND="benchmark --endpoints=${ENDPOINTS} --conns=100 --clients=100 range a z --consistency=l --total=100000"
bench3roundsfilled "$BENCH_COMMAND" "$TEST_COMMAND"

echo "*********************** benchmark B23 **********************" >> ${OUTPUT_FILE}
BENCH_COMMAND="benchmark --endpoints=${ENDPOINTS} --conns=100 --clients=1000 range a z --consistency=l --total=100000"
bench3roundsfilled "$BENCH_COMMAND" "$TEST_COMMAND"

echo "*********************** benchmark B24 **********************" >> ${OUTPUT_FILE}
BENCH_COMMAND="benchmark --endpoints=${ENDPOINTS} --conns=100 --clients=1000 range a z --consistency=l --total=1000000"
bench3roundsfilled "$BENCH_COMMAND" "$TEST_COMMAND"

echo "Script execution has completed successfully :)" >> ${OUTPUT_FILE}

