#!/bin/bash

# the basis parameter
##########################################################
######################## parameter #######################
##########################################################
rootpath="/home/ubuntu/Desktop/merge"
sharepath="$rootpath/share_data"



# docker&user parameter
# nvidia/cuda:9.0-cudnn7-devel
##########################################################
######################## parameter #######################
##########################################################
cuda_name="nvidia/cuda:9.0-cudnn7-devel" #################

##########################################################
######################## parameter #######################
##########################################################
username="xxxxx" #########################################
userport="12345" #########################################


# node parameter
######################## parameter #######################
IPLIST=("8.8.8.8"  "8.8.4.4")   #########################
NAMELIST=("ubuntu" "ubuntu")    #########################
PASSWDLIST=("ubuntu" "ubuntu")  #########################


######################################
###    establish the store node    ###
######################################
mkdir $sharepath
mkdir $sharepath/public_data
if [ ! -d "$sharepath/$username" ]; then
	mkdir $sharepath/$username
	mkdir $sharepath/$username/datafile
#else
#	exit
fi
echo "establis the store node done!"

##########
# here I define the $rootpath/share as the share node
# $rootpath/share/$username contains systemfile & datafile for each user
# $rootpath/share/public_data contains public data for whole users
##########
# how to make nfs:   https://blog.csdn.net/CSDN_duomaomao/article/details/77822883

########################################
###   prepare the share systemfile   ###
########################################
echo "FROM $cuda_name" > Dockerfile
cat dockerfile_base >> Dockerfile
###################docker build -t ${username}_image  .
if [ ! -d "$sharepath/$username/systemfile" ]; then
	mkdir $sharepath/$username/systemfile
	docker run --gpus all -d -p 6789:22 -v $sharepath"/$username/systemfile":/home/songjf --name master_temp ${username}_image
	docker exec -it master_temp bash -c "cp -r  /bin /etc /lib /lib64 /opt /root /sbin /usr /home/songjf   && echo 'fuck'  && exit"
	docker container stop master_temp
	docker container rm  master_temp
fi
docker save ${username}_image > $sharepath/$username/store_image.tar
#docker image rm ${username}_image
echo "prepare the share systemfile done!"
########################################
###    make the docker container     ###
########################################

for(( i=0;i<${#IPLIST[@]};i++)) do


/usr/bin/expect << EOF
set timeout 300
spawn ssh ${NAMELIST[i]}@${IPLIST[i]}
expect {
		"(yes/no)" {send "yes\r"; exp_continue}
		"password:" {send "${PASSWDLIST[i]}\r"}
}
expect "${NAMELIST[i]}@*"  {send "docker load < /home/${NAMELIST[i]}/Desktop/share_data/$username/store_image.tar\r"}
sleep 1
expect "${NAMELIST[i]}@*"  {send "docker run --gpus all -d -p $userport:22  -v /home/${NAMELIST[i]}/Desktop/share_data/$username/systemfile/bin:/bin -v /home/${NAMELIST[i]}/Desktop/share_data/$username/systemfile/etc:/etc -v /home/${NAMELIST[i]}/Desktop/share_data/$username/systemfile/lib:/lib -v /home/${NAMELIST[i]}/Desktop/share_data/$username/systemfile/lib64:/lib64 -v /home/${NAMELIST[i]}/Desktop/share_data/$username/systemfile/opt:/opt -v /home/${NAMELIST[i]}/Desktop/share_data/$username/systemfile/root:/root -v /home/${NAMELIST[i]}/Desktop/share_data/$username/systemfile/sbin:/sbin -v /home/${NAMELIST[i]}/Desktop/share_data/$username/systemfile/usr:/usr -v /home/${NAMELIST[i]}/Desktop/share_data/$username/datafile:/home/data_personal -v /home/${NAMELIST[i]}/Desktop/share_data/public_data:/home/data_public -h node$i --name  $username  ${username}_image\r"}
sleep 1
expect "${NAMELIST[i]}@*"  {send "exit\r"}
EOF

done;
echo "make container done!"

########################################################
###    make the ssh between dockers passwordless     ###
########################################################


for(( i=0;i<${#IPLIST[@]};i++)) do


/usr/bin/expect << EOF
set timeout 30
spawn ssh root@${IPLIST[i]} -p $userport
expect {
		"(yes/no)" {send "yes\r"; exp_continue}
		"password:" {send "songjf\r"}
}
expect "root@*"  {send "ssh-keygen -t rsa\r"}
expect {
		"Enter file in which to save the key (/root/.ssh/id_rsa)" {send "\r";exp_continue}
		"Overwrite (y/n)" {send "y\r";exp_continue}
		"(empty for no passphrase)" {send "\r";exp_continue}
		"Enter same passphrase again" {send "\r"}
}
sleep 3
expect "root@*"  {send "cd /root/.ssh\r"}
expect "root@*"  {send "cat id_rsa.pub >> authorized_keys\r"}
expect "root@*"  {send "echo 'Host node$i' >> ~/.ssh/config\r"}
expect "root@*"  {send "echo 'User root' >> ~/.ssh/config\r"}
expect "root@*"  {send "echo 'Hostname ${IPLIST[i]}' >>  ~/.ssh/config\r"}
expect "root@*"  {send "echo 'Port $userport'  >> ~/.ssh/config\r"}
expect "root@*"  {send "echo ' '  >> ~/.ssh/config\r"}
expect "root@*"  {send "chmod 700 ~/.ssh\r"}
expect "root@*"  {send "chmod 600 ~/.ssh/authorized_keys\r"}

expect "root@*"  {send "exit\r"}
EOF

done;
echo "passwordless done"