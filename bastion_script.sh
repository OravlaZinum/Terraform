#! /bin/bash 

#Delete possible old installation
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

#Update repositories
apt update 

#Install dependencies
apt-get install -y\
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    software-properties-common
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

#Añadimos repositorio
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

#Installing packages
apt update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#For security, only root can execute the docker command
usermod -aG docker ${USER}
curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#Enable odcker to start within system
systemctl enable docker
systemctl start docker

#Install peco
sudo apt-get install -y peco
#Install gc_connect
cd /usr/local/bin
cat <<'EOF' > gc
#!/bin/bash
#Installing path /usr/local/bin
# If the rule exists, delete it previously.
#
# If the project or network is not specified, a list is displayed to choose from
#
# When the connection ends, the created rule is deleted.
if [ $1 ]; then
        project_name="--project $1"
fi

if [ $2 ]; then
        name="$2"
fi

if  [[ ! $project_name ]];  then
       project=($(gcloud projects list | peco --initial-index 1))
       project_name="--project ${project[0]}"
fi;

if  [ ! $name ]; then
        instance=($(gcloud compute networks list ${project_name} | peco --initial-index 1))
        name=${instance[0]}
fi

network_name=$name
echo -e "Deleting lastest rule...\n"
gcloud compute --project=$project firewall-rules delete fw-${USER}-$name --quiet
echo "gcloud compute --project=$project firewall-rules create fw-${USER}-$name --direction=INGRESS --priority=1000 --network=$name --action=ALLOW --rules=tcp:3389,tcp:2222,tcp:22,tcp:80,tcp:81,tcp:443 --source-ranges=`curl ifconfig.co/ip`/32"

gcloud compute --project=$project firewall-rules create fw-${USER}-$name --direction=INGRESS --priority=1000 --network=$name --action=ALLOW --rules=tcp:3389,tcp:2222,tcp:22,tcp:80,tcp:81,tcp:443 --source-ranges=`curl ifconfig.co/ip`/32

# It is an option if you do not want to delete the rule (at the end of the script), it is saved in a file. When you execute gcfirewall-delete, the delete commands that we have been storing are executed
#echo "gcloud compute --project=$project firewall-rules delete fw-${USER}-${name} -q" >> ~/.local/bin/gcfirewall-delete-list
#echo "*** Pending rules to remove ***"
#at ~/.local/bin/gcfirewall-delete-list

instance=($(gcloud compute instances list ${project_name} | peco --initial-index 1))
name=${instance[0]}
zone=${instance[1]}

gcloud compute ssh --zone "$zone" ${project_name}  $name
echo "Deleting the FW rule"
gcloud compute --project=$project firewall-rules delete fw-${USER}-${network_name} -q
echo "gcloud compute ssh $name --zone "$zone" ${project_name}"
## END
EOF

#Change scripts permisions
sudo chmod a+rx /usr/local/bin/gc
