#!/bin/bash
# Testnets.io

title="Nym Manager"
version="Version 1.0"

function show_title {
  clear 
  # todo - only curl this once. 
  curl -s testnets.io/core/logo.sh | bash # grab testnets.io ascii logo
  printf "\n\u001b[33;1m$title - $version\e[0m\n\n"  
}

function show_feedback {
  echo -e "> \u001b[32;1m$feedback\e[0m\n"
}

prompt='Select:'
options=(
    "Nym Installation"
    "Nym Status"
    "Query Systemd Journal With Journalctl"
    "Nym Help"
    "Socket Statistics"
    "Stop Nym Service"
    "Start Nym Service"
    "Bond Information"
    "Quit"
)

function node_install  { 
read -p "Please enter your node ID: " node_id
echo 'Your node ID is : ' $node_id
read -p "Please enter your wallet address: " wallet_address
echo 'Your wallet address is : ' $wallet_address
echo 'export node_id='$node_id >> $HOME/.bash_profile
echo 'export wallet_address='$wallet_address >> $HOME/.bash_profile
source $HOME/.bashrc
source $HOME/.bash_profile

sudo apt update -y && sudo apt upgrade -y < "/dev/null"
sudo apt install wget pkg-config build-essential libssl-dev curl jq -y
sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME"/.cargo/env
sleep 1
cd "$HOME" || exit
wget https://github.com/nymtech/nym/releases/download/nym-binaries-1.0.0-rc.2/nym-mixnode
sudo chmod +x nym-mixnode
sudo mv "$HOME"/nym-mixnode /usr/bin

sudo tee <<EOF >/dev/null /etc/systemd/system/nym-mixnode.service
[Unit]
Description=Nym Mixnode (1.0.0rc1)
StartLimitInterval=350
StartLimitBurst=10
[Service]
User=$USER
LimitNOFILE=65536
ExecStart=/usr/bin/nym-mixnode run --id '$node_id'
KillSignal=SIGINT
Restart=on-failure
RestartSec=30
[Install]
WantedBy=multi-user.target
EOF

sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF


sudo apt install ufw -y
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 1789
sudo ufw allow 1790
sudo ufw allow 8000
sudo ufw --force enable
echo "Firewall Rules Added & Enabled"

source $HOME/.bash_profile
nym-mixnode init --id $node_id --host $(curl ifconfig.me) --wallet-address $wallet_address

echo "DefaultLimitNOFILE=65535" >> /etc/systemd/system.conf
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable nym-mixnode
sudo systemctl start nym-mixnode
echo "Nym Sandbox Instalation has Finished & Started"

}
function node_status   { 
sudo systemctl status nym-mixnode
}
function check_journalctl {
sudo journalctl -u nym-mixnode -o cat | grep "Since startup mixed"
read -p "Press enter to continue"
}
function nym_help { 
/usr/bin/nym-mixnode --help
read -p "Press enter to continue"
}
function socket_statisics { 
sudo ss -s -t | grep 1789 # if you have specified a different port in your mixnode config, change accordingly
read -p "Press enter to continue"
}
function stop_nym_service { 
sudo systemctl stop nym-mixnode
echo "Nym Service Stoped"
sleep 1
}
function start_nym_service   { 
sudo systemctl start nym-mixnode
echo "Nym Service Started"
sleep 1
}
function bond_information   { 
source $HOME/.bash_profile
nym-mixnode node-details --id $node_id
read -p "Press enter to continue"
}
function quit          { 
  echo -e "Exiting ... " ; exit 
}
function not_option    { 
  echo -e "That is not an option" 
}

# set new prompt, newline is needed here. 
PS3="
$prompt" 

function show_menu {
  select option in "${options[@]}"; do
    case $REPLY in 
       1 ) node_install         ; break ;;
       2 ) node_status          ; break ;;
       3 ) check_journalctl     ; break ;;
       4 ) nym_help             ; break ;;
       5 ) socket_statisics     ; break ;;
       6 ) stop_nym_service     ; break ;;
       7 ) start_nym_service    ; break ;;
       8 ) bond_information     ; break ;;
       9 ) quit                 ; break ;;
       * ) not_option           ; break ;;
    esac
  done
}

# do it once/first without feedback, 
show_title
show_menu 

while ( true ) do 
  
  sleep 2 
  show_title
  show_feedback
  show_menu  
  
done
