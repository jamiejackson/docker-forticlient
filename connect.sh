#!/usr/bin/env bash
set -e

while :
do
  case $1 in
    --domain=*)
      domain=${1#*=}
      shift
      ;;
    --cidr=*)
      cidr=${1#*=}
      shift
      ;;
    --nameservers=*)
      nameservers=${1#*=}
      shift
      ;;
    -*)
      echo "WARN: Unknown option (ignored): $1" >&2
      shift
      ;;
    *)  # no more options. Stop while loop
      break
      ;;
  esac
done

function myecho {
  BLACK=`tput setaf 0`
  RED=`tput setaf 1`
  GREEN=`tput setaf 2`
  YELLOW=`tput setaf 3`
  BLUE=`tput setaf 4`
  MAGENTA=`tput setaf 5`
  CYAN=`tput setaf 6`
  WHITE=`tput setaf 7`
  
  BOLD=`tput bold`
  RESET=`tput sgr0`
  
  echo -e "${GREEN}$1${RESET}"
}

if [ -z "$domain" ] || [ -z "$cidr" ] || [ -z "$nameservers" ]; then
    echo "Must provide --domain=<domain> --cidr=<cidr> --nameservers=<nameservers>" 1>&2
    exit 1
fi

myecho "ensuring sudo password is cached (this isn't the VPN password)"
sudo echo ""

myecho "create an intermediate boot2docker virtual machine"
docker-machine create fortinet --driver virtualbox || true
myecho "start boot2docker, if it's not already up"
docker-machine start fortinet || true
myecho "get into the boot2docker context"
eval $(docker-machine env fortinet)
myecho "build the image"
docker-compose build --pull

myecho "creating a custom resolver so that the domain's dns is used"
sudo mkdir -p /etc/resolver
myecho "removing resolver, if it exists"
sudo rm -f "/etc/resolver/$domain"
myecho "building custom resolver"
# split multiple nameservers
IFS=',' read -ra nameserver_ary <<< "$nameservers"
for nameserver in "${nameserver_ary[@]}"; do
  printf "nameserver $nameserver" | sudo tee -a "/etc/resolver/$domain"
done

myecho "creating routes through the vpn for ips on the subnet"
sudo route add -net "$cidr" $(docker-machine ip fortinet)
myecho "getting into the context of the boot2docker machine"
eval $(docker-machine env fortinet)
myecho "starting vpn client"
docker-compose run --name vpnc --rm vpnc