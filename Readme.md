# Fortinet VPN Client with MFA

The original project, https://github.com/AuchanDirect/docker-forticlient, doesn't seem to
handle multi-factor authentication (MFA).

However, this project doesn't automate password submission. (See TODOs.)

The documentation is currently Mac-only.

## Get Started

```sh
git clone https://github.com/jamiejackson/docker-forticlient.git
cd docker-forticlient
git checkout mfa
```

Set environment variables by copying `.env_template` to `.env`, then edit `.env` to contain your own values.

## Automatic Convenience Script

This is an automatic version of the "Manual Steps" documented below.

`./launch.sh --domain=thedomain.wan --cidr='10.80.0.0/16' --nameservers='10.80.1.10,10.80.1.11'`

* `domain` is the domain of the WAN whose hosts to which you intend to connect.
* `cidr` is the subnet IP range of the hosts to which you intend to connect.
* `nameservers` provide the DNS for the hosts to which you intend to connect.

## Manual Steps

## One-Time Setup

### Clone Project

```sh
git clone https://github.com/jamiejackson/docker-forticlient.git
cd docker-forticlient
git checkout mfa
```

### Setup VM and Build

Setup a small VM and build the docker image.

```sh
# create an intermediate boot2docker virtual machine
docker-machine create fortinet --driver virtualbox
# get into the boot2docker context
eval $(docker-machine env fortinet)
# build the image
docker-compose build --pull
```

### Setup DNS

Note: The following uses a domain of `thedomain.wan`, but yours will be different.

```sh
# prep for a custom resolver
sudo mkdir -p /etc/resolver
# add custom resolver
sudo bash -c 'cat > /etc/resolver/thedomain.wan <<EOF
nameserver 10.80.1.10
nameserver 10.80.1.11
EOF'
```

## Per VPN Session

Note, my project has a CIDR of `10.80.0.0/16`; yours will be different.

```
# start boot2docker, if it's not already up
docker-machine start fortinet
# create a route for your subnet
sudo route add -net 10.80.0.0/16 $(docker-machine ip fortinet)
# get into the context of the boot2docker machine.
eval $(docker-machine env fortinet)
# start up vpn client. accept the prompts, type password, and accept mfa prompt
docker-compose run --name vpnc --rm vpnc
```

# Notes

Removing route (while troubleshooting): `ip route del 10.80.0.0/16`

# TODO

* Figure out the `expect` necessary for automating the password submission when also using
  MFA? (I tried to figure out what the expect wanted, but it was tough.)
  
  
----

Upstream README:


# forticlient

Connect to a FortiNet VPNs through docker

## Usage

The container uses the forticlientsslvpn_cli linux binary to manage ppp interface

All of the container traffic is routed through the VPN, so you can in turn route host traffic through the container to access remote subnets.

### Linux

```bash
# Create a docker network, to be able to control addresses
docker network create --subnet=172.20.0.0/16 fortinet

# Start the priviledged docker container with a static ip
docker run -it --rm \
  --privileged \
  --net fortinet --ip 172.20.0.2 \
  -e VPNADDR=host:port \
  -e VPNUSER=me@domain \
  -e VPNPASS=secret \
  auchandirect/forticlient

# Add route for you remote subnet (ex. 10.201.0.0/16)
ip route add 10.201.0.0/16 via 172.20.0.2

# Access remote host from the subnet
ssh 10.201.8.1
```

### OSX

```
UPDATE: 2017/06/10
Docker's microkernel still lacks ppp interface support, so you'll need to use a docker-machine VM.
```

```bash
# Create a docker-machine and configure shell to use it
docker-machine create fortinet --driver virtualbox
eval $(docker-machine env fortinet)

# Start the priviledged docker container on its host network
docker run -it --rm \
  --privileged --net host \
  -e VPNADDR=host:port \
  -e VPNUSER=me@domain \
  -e VPNPASS=secret \
  auchandirect/forticlient

# Add route for you remote subnet (ex. 10.201.0.0/16)
sudo route add -net 10.201.0.0/16 $(docker-machine ip fortinet)

# Access remote host from the subnet
ssh 10.201.8.1
```

## Misc

If you don't want to use a docker network, you can find out the container ip once it is started with:
```bash
# Find out the container IP
docker inspect --format '{{ .NetworkSettings.IPAddress }}' <container>

```

### Precompiled binaries

Thanks to [https://hadler.me](https://hadler.me/linux/forticlient-sslvpn-deb-packages/) for hosting up to date precompiled binaries which are used in this Dockerfile.
