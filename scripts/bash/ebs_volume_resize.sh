#!/bin/bash
# ebs_volume_resize.sh
# USAGE: sh ebs_volume_resize.sh [instance_id] [volume_id] [size]
 
instanceid=$1
volumeid=$2
size=$3
 
echo "Increasing volume $2 on $1 to $3 GB";
echo "Stop all reading/writing to the volume to resize";
 
zone=$(ec2-describe-instances $instanceid | egrep ^INSTANCE | cut -f12)
device=$(ec2-describe-volumes $volumeid | egrep ^ATTACHMENT |  cut -f4)
 
echo "Detaching volume $volumeid";
while ! ec2-detach-volume $volumeid; do sleep 1; done
 
echo "Creating snapshot..."
snapshotid=$(ec2-create-snapshot $volumeid | cut -f2)
while ec2-describe-snapshots $snapshotid | grep -q pending; do sleep 1; done
echo "snapshot: $snapshotid"
 
echo "Creating volume..."
newvolumeid=$(ec2-create-volume --availability-zone $zone --size $size --snapshot $snapshotid | cut -f2)
echo "New volume: $newvolumeid"
 
echo "Attaching new volume..."
ec2-attach-volume --instance $instanceid --device $device $newvolumeid
while ! ec2-describe-volumes $newvolumeid | grep -q attached; do sleep 1; done
 
echo "to delete previous volume, type: ec2-delete-volume $volumeid"
echo "to delete snapshot, type: ec2-delete-snapshot $snapshotid"
 
echo "All done. Resizing completed."
