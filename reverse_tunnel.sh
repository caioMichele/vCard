#!/bin/bash
#
#
#
#
jump_server_ip="jump_server_ip_to_change"
ssh_port_on_server="2222"
local_socks_port="1080"
#
#
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
reset=`tput sgr0`
#
#
#

#-------------------------------------------------------------------------------------------------
# Check SOCKS tunnel 
#

socks_listening=$(netstat -an | grep 127.0.0.1:"$local_socks_port" | grep -i listen)
if [ -z "$socks_listening" ]
then
    echo "${green} *** Starting local SOCKS proxy *** ${reset}"
    eval "ssh -Nf -D 127.0.0.1:$local_socks_port localhost"
else 
    echo "${red} *** nooooo *** ${reset}"
fi

#COMMAND="ssh -fnNR $local_socks_port:127.0.0.1:$local_socks_port twosecclient@$jump_server_ip"
#pgrep -f -x "$COMMAND"
socks_connected=$(ssh twosecclient@$jump_server_ip netstat -ant | egrep "tcp.*127.0.0.1:$local_socks_port.*LISTEN")
if [ -z "$socks_connected" ]
then
	echo "${green} *** Starting proxy connection to jump server *** ${reset}"
    eval "ssh -fnNR $local_socks_port:127.0.0.1:$local_socks_port twosecclient@$jump_server_ip 2>/dev/null"
fi



#-------------------------------------------------------------------------------------------------
# Check SSH tunnel
#

ssh_connected=$(ps -ef | grep "$ssh_port_on_server:127.0.0.1:22")
if [ -n "$ssh_connected" ]
then
    echo "${green} *** Starting SSH connection to jump server *** ${reset}"
    eval "ssh -fnNR $ssh_port_on_server:127.0.0.1:22 twosecclient@$jump_server_ip"
fi




#-------------------------------------------------------------------------------------------------
# Check SOCKS tunnel 
#

socks_listening=$(netstat -an | grep 127.0.0.1:"$local_socks_port" | grep -i listen)
if [ -n "$socks_listening" ]
then
    echo "${green} *** Starting local SOCKS proxy *** ${reset}"
    eval "ssh -Nf -D 127.0.0.1:$local_socks_port localhost"
fi

#COMMAND="ssh -fnNR $local_socks_port:127.0.0.1:$local_socks_port twosecclient@$jump_server_ip"
#pgrep -f -x "$COMMAND"
socks_connected=$(ssh twosecclient@$jump_server_ip netstat -ant | egrep "tcp.*127.0.0.1:$local_socks_port.*LISTEN")
if [ -n "$socks_connected" ]
then
	echo "${green} *** Starting proxy connection to jump server *** ${reset}"
    eval "ssh -fnNR $local_socks_port:127.0.0.1:$local_socks_port twosecclient@$jump_server_ip 2>/dev/null"
fi


#ssh -i "2sec-primary-key.pem" -L 5555:127.0.0.1:1080  ubuntu@18.130.162.245