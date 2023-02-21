# Don't even think of messing with this if you aren't me
#
# $1 = environment
# $2 = Project

CFGPATH="/usr/local/prometheus/etc/dynamic-configs/"

profile=$1
job_target=$2
filename="$job_target-$profile-config.yml"

filename="${filename// /_}"
filename="$CFGPATH/$filename"

job="$job_target-servers"
job="${job// /_}"

# Get the tags for the instance
tags=$(aws --profile $profile ec2 describe-tags --filters "Name=tag:Project,Values=$job_target" --output json)

instance=$(echo "$tags" | jq '.[]' | jq '.[].ResourceId')

if [ "$instance" == "" ];
then
        echo "no servers in $profile for $job_target"
        exit
fi

#echo "servers found: $tags"

#echo "writing to file $filename"

echo "-targets:" > $filename

for loop in $instance;
do

        #targets=$(sed -e 's/^"//' -e 's/"$//' <<< "$loop")
        targets="${loop%\"}"
        targets="${targets#\"}"

        if ! [[ "$targets" =~ "ami-" ]];
        then
          #echo "checking target: $targets"

          InstanceDump=$(aws --profile $profile ec2 describe-instances --instance-id $targets)

          ip=$(echo "$InstanceDump" | jq '.[]' | jq '.[].Instances' | jq '.[].PrivateIpAddress')

          #target=$(sed -e 's/^"//' -e 's/"$//' <<< "$ip")
          target="${ip%\"}"
          target="${target#\"}"

          echo "  - $target:9100" >> $filename

        fi



done

echo "  labels:" >> $filename
echo "          task_name: $profile" >> $filename
echo "          job: $job_target-servers" >> $filename



