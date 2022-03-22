#!/bin/bash
#
# -------------------------------
# 	PRE SETUP steps - kali box
# -------------------------------
#
# # Change NAT to Bridged
#
#
#
# # Enable root
# sudo su
# passwd 
#
# # Initial configurations 
#
# systemctl enable ssh.service
# systemctl start ssh.service
# apt-get update && apt-get -y install open-vm-tools-desktop
# systemctl enable open-vm-tools.service
# reboot
#



# ------------------------------ CAMILLA IS HERE ------------------------------
# # Add the ubuntu public key to the root authorized_keys
#
# mkdir .ssh
# echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+BIkhxovAfTfmmkbgTkjoy0C1djQYLnjU/oJgdtrmMFqT4wlPHHTmVr3nWaN98UoNhPngQ4kYF8ZXfLnI59sGfSYmpQ+JoNDPS9dmmSdwOyaVvBuH/EzqTR1g32jD9ABiTAV+iq+wdHS7F4RuwcsyGs5gNPHqwfSVwT0cRr2eE81IDUJ94KNPP+VUDdYYKhMzQwPUmeuf1C7GF3vuqacOGQ/BwxYGlqTa5XiNkMCdN51ucXqFOvT1/AZB0nW0lW2NK8UTfoNFZxqDhbR85ePp12H4Atdp1ur1AItvqoS3BFesC+YCWO41vKCFG9D/IrOMLZLN/VY1GdDhqLNgQqPd root@ip-172-31-20-185"  >> /root/.ssh/authorized_keys 

# chmod 700 .ssh
# chmod 640 .ssh/authorized_keys
#

# # Run setup script
#
# chmod +x ./SetupClient.sh
# ./SetupClient.sh
#
#

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
reset=`tput sgr0`


#-----------------------------------------------------------------------------------------
echo "${yellow}*************************************************************"
echo "     This script will set up the Virtual Machine for 2-Sec "
echo " ************************************************************* ${reset}"
#-----------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------
# Check if root

local_user=$(whoami)
expected_user="root"

if [[ $local_user != $expected_user ]]; then
	echo "${red} >>> Please run the script as the \"root\" user <<< ${reset}"
	exit 0
fi


#-----------------------------------------------------------------------------------------
# Get/check jump server IP address
echo -n "${green} >>> Enter the (provided) jump server IP: ${reset}"
read server_ip

if expr "$server_ip" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
  echo ""
else
   echo "${red} >>> Error: Enter a valid IP address <<<{reset}"
   exit 0
fi


#-----------------------------------------------------------------------------------------
# Check if we are in AWS
in_aws=false
bios_info=$(dmidecode -s bios-version | awk '{print tolower($0)}')

if grep -q "amazon" <<< "$bios_info"; then
  in_aws=true
fi

#-----------------------------------------------------------------------------------------
# Install updates
echo "${green} *** Installing updates *** ${reset}"
export DEBIAN_FRONTEND=noninteractive
apt-get -y update
# https://askubuntu.com/questions/104899/make-apt-get-or-aptitude-run-with-y-but-not-prompt-for-replacement-of-configu
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
apt-get -y autoremove


# We need to reinstall grub for AWS instances
if $in_aws; then
	echo "${green} *** Reinstalling grub for AWS instances *** ${reset}"
	grub-install /dev/xvda
	grub-install /dev/xvda1
fi


#-----------------------------------------------------------------------------------------
# Configure SSH 
echo "${green} *** Configuring the SSH service *** ${reset}"

# backup conf files 
cp /etc/ssh/ssh_config /root/ssh_config.old
cp /etc/ssh/sshd_config /root/sshd_config.old


echo "${green} *** Modifying sshd_config file *** ${reset}"
if $in_aws; then
	echo "" >> /etc/ssh/sshd_config
    echo "PermitTunnel yes" >> /etc/ssh/sshd_config
    echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
else
	sed -i "s/PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config
	sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config
	sed -i "s/AllowTcpForwarding no/AllowTcpForwarding yes/" /etc/ssh/sshd_config
	sed -i "s/#AllowTcpForwarding yes/AllowTcpForwarding yes/" /etc/ssh/sshd_config
	sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
	sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/" /etc/ssh/sshd_config
fi

sed -i "s/#PermitTunnel no/PermitTunnel yes/" /etc/ssh/sshd_config
sed -i "s/#TCPKeepAlive yes/TCPKeepAlive yes/" /etc/ssh/sshd_config


echo "${green} *** Modifying ssh_config file *** ${reset}"

echo "ServerAliveInterval 60" >> /etc/ssh/ssh_config
echo "UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config
sed -i "s/#   Tunnel no/Tunnel yes/" /etc/ssh/ssh_config
sed -i "s/Tunnel no/Tunnel yes/" /etc/ssh/ssh_config
sed -i "s/#   ForwardX11 no/ForwardX11 yes/" /etc/ssh/ssh_config
sed -i "s/ForwardX11 no/ForwardX11 yes/" /etc/ssh/ssh_config
sed -i "s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/" /etc/ssh/ssh_config


# Start the SSH server
service ssh restart
systemctl enable ssh.service

# AWS Kali instance needs to setup /run/sshd on each reboot.
# https://askubuntu.com/questions/1109934/ssh-server-stops-working-after-reboot-caused-by-missing-var-run-sshd/1110843#1110843
if $aws; then
	echo "d /run/sshd 0755 root root" > /usr/lib/tmpfiles.d/sshd.conf
fi


#-----------------------------------------------------------------------------------------
# Checking for the root ssh key
if [ ! -f /root/.ssh/id_rsa ]; then
   # Root ssh key not found
   echo 
   ssh-keygen -f /root/.ssh/id_rsa -N ""
   cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
   chmod 600 /root/.ssh/id_rsa*
else 
   # Root ssh key found 
   cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
   chmod 600 /root/.ssh/id_rsa*
fi



#-----------------------------------------------------------------------------------------
# Configure Reverse tunnel script

cron_job="*/5 * * * *"
cron_cmd="/root/reverse_tunnel.sh"

mv ./reverse_tunnel.sh $cron_cmd 2>/dev/null  

sed -i "s/jump_server_ip_to_change/$server_ip/" /root/reverse_tunnel.sh

chmod +x /root/reverse_tunnel.sh


echo "${green} *** Adding a Cron job to run the reverse tunnel script every 5 minutes *** ${reset}"

crontab -l > crontab_new 
if ! grep -q "$cron_job $cron_cmd" crontab_new
then
   echo "$cron_job $cron_cmd" >> crontab_new
   crontab crontab_new
fi
rm crontab_new

#Another option 
#Add it to the crontab, with no duplication:
#( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
# To remove it from the crontab whatever its current schedule:
#( crontab -l | grep -v -F "$croncmd" ) | crontab -
# ( crontab -l | grep -v -F "/root/reverse_tunnel.sh" ) | crontab -


#-----------------------------------------------------------------------------
# Final test to see if the jump server ssh port can be reached
nc -q 0 -w 1 $server_ip 22 < /dev/null &> /dev/null && test="Reachable" || test="Unreachable"

if [[ $test != "Reachable" ]] ; then
	echo "${red} >>> The server can not be reached. Please ensure that outbound SSH connections are allowed <<< ${reset}"
fi



#-----------------------------------------------------------------------------
# Send us the info 
echo "${cyan} -------------------------------------------------------"
echo "-------------------------------------------------------"
echo " >>> Please send the following information to 2-Sec<<<"
echo "-------------------------------------------------------"
echo "-------------------------------------------------------"
echo " Public Key:"
echo "$(cat /root/.ssh/id_rsa.pub)"
echo "-------------------------------------------------------"
echo "------------------------------------------------------- ${reset}"



echo "${blue} *** Please reboot the VM once the key has been sent *** ${reset}"