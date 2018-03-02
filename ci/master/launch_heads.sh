#!/bin/bash
# This script is executed on the compute node
#SBATCH -p compile # partition (queue) 
#SBATCH -N 1 # number of nodes 
#SBATCH -n 1 # number of cores 
#SBATCH --mem 100 # memory pool for all cores 
#SBATCH -t 0-2:00 # time (D-HH:MM) 
#SBATCH -o slurm.%N.%j.out # STDOUT 
#SBATCH -e slurm.%N.%j.err # STDERR
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

machine_name=ubuntu

#preparing the run
scp -o StrictHostKeyChecking=no $USER@bastion:/var/images/$machine_name.img $HOME/images/$machine_name.$SLURM_JOB_ID.img
# I must upload my public key into the VM otherwise I will not be able to ssh to it
mkdir mnt.$SLURM_JOB_ID
guestmount -a $HOME/images/$machine_name.$SLURM_JOB_ID.img -m /dev/sda1 mnt.$SLURM_JOB_ID
if [ ! -f $HOME/.ssh/id_rsa.pub ]; then
	cat /dev/zero | ssh-keygen -q -N "" > /dev/null
fi
\mkdir mnt.$SLURM_JOB_ID/home/sds/.ssh
# Allow sudo for the sds account without password
echo "sds     ALL=(ALL) NOPASSWD: ALL" >> mnt.$SLURM_JOB_ID/etc/sudoers
cat $HOME/.ssh/id_rsa.pub >& mnt.$SLURM_JOB_ID/home/sds/.ssh/authorized_keys
chown -Rf 1000:1000 mnt.$SLURM_JOB_ID/home/sds/.ssh
guestunmount mnt.$SLURM_JOB_ID
\rm -Rf mnt.$SLURM_JOB_ID
# We can boot the VM but we need the config file
scp $USER@bastion:/var/images/config.$machine_name.xml $HOME/kvm/config.xml
cat $HOME/kvm/config.xml | sed "s+IMAGE_URI+\"$HOME/images/$machine_name.$SLURM_JOB_ID.img\"+" >& /tmp/config.new
cp /tmp/config.new $HOME/kvm/config.$SLURM_JOB_ID.xml
cd $HOME/kvm/
# We must change the domain name
cat $HOME/kvm/config.$SLURM_JOB_ID.xml | sed "s/<name>$machine_name/<name>$machine_name-$SLURM_JOB_ID/" >& /tmp/config.new
cp /tmp/config.new $HOME/kvm/config.$SLURM_JOB_ID.xml
# and we must provide a unique UUID
myuuid=`uuidgen`
cat $HOME/kvm/config.$SLURM_JOB_ID.xml | sed "s/UUID/$myuuid/" >& /tmp/config.new
cp /tmp/config.new $HOME/kvm/config.$SLURM_JOB_ID.xml
# I am just adding the job name
virsh create config.$SLURM_JOB_ID.xml

# This shall be done on a thread
# Must loop up to the time the VM comes up
sleep 120
# Must get the internal IP address of the VM
max_retry=60
myvmip=""
while [ "$myvmip" == "" ] && [ "$max_retry" -gt 0 ]
do
	sleep 5
	myvmip=`$HOME/find_ip $machine_name-$SLURM_JOB_ID`
	max_retry=$((max_retry-1))
done
echo $myvmip
if [ "$myvmip" == "" ]; then
	# We got an error the VM doesn't have networking
	echo "No IP detected"
fi
# We must wait that ssh runs (we can have an IP and the daemon is still not running)
is_ssh_running=`nmap -p22 $myvmip | grep -i open`
max_retry=60
while [ "$is_ssh_running" == "" ]
do
	sleep 5
	is_ssh_running=`nmap -p22 $myvmip | grep -i open`
done

if [ "$is_ssh_running" == "" ]
then
	# ssh server is not running
	echo "SSH server not running in VM"
fi
ssh -o StrictHostKeyChecking=no sds@$myvmip hostname
# Must copy the job into the vm
# TODO copy into the running vm
mkdir job.$SLURM_JOB_ID
scp -o StrictHostKeyChecking=no $USER@bastion:build_heads job.$SLURM_JOB_ID/build_heads
scp -o StrictHostKeyChecking=no $USER@bastion:/var/images/bios/winterfell.rom job.$SLURM_JOB_ID/winterfell.rom
scp -o StrictHostKeyChecking=no job.$SLURM_JOB_ID/winterfell.rom sds@$myvmip:winterfell.rom
scp -o StrictHostKeyChecking=no job.$SLURM_JOB_ID/build_heads sds@$myvmip:build_heads
ssh -o StrictHostKeyChecking=no sds@$myvmip chmod 755 build_heads
ssh -o StrictHostKeyChecking=no -tt sds@$myvmip ./build_heads
ssh -o StrictHostKeyChecking=no sds@$myvmip ls -l
scp sds@$myvmip:heads/build/winterfell/linuxboot.rom job.$SLURM_JOB_ID/linuxboot_winterfell.rom
# We must trasnfer the iso file to bastion
ssh -o StrictHostKeyChecking=no $USER@bastion mkdir job.$SLURM_JOB_ID
scp job.$SLURM_JOB_ID/linuxboot_winterfell.rom $USER@bastion:job.$SLURM_JOB_ID/linuxboot_winterfell.rom
# ssh -o StrictHostKeyChecking=no $USER@bastion ./setup_pxe $SLURM_JOB_ID
#rm -Rf job.$SLURM_JOB_ID
# Must execute the job into the vm and get the output

# end of the thread

virsh destroy $machine_name-$SLURM_JOB_ID
cd $HOME/kvm/
rm config.$SLURM_JOB_ID.xml
#cleaning up the run
\rm $HOME/images/$machine_name.$SLURM_JOB_ID.img
