#!/bin/bash
TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='stintcoin.conf'
CONFIGFOLDER='/root/.stintcoin/'
COIN_DAEMON='stintcoind'
COIN_CLI='stintcoin-cli'
COIN_PATH='/usr/local/bin/'
COIN_TGZ='https://github.com/stintcoin/StintCoin/releases/download/v1.1.1/stintcoin-1.1.1-x86_64-linux-gnu.tar.gz'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
COIN_NAME='StintCoin'
COIN_PORT=27501
RPC_PORT=27502
NODEIP=$(curl -s4 api.ipify.org)

NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
BOLD='\033[1m'
STEPS=10

function prepareSystem() {
  clear
  cd

  echo
  echo -e "--------------------------------------------"
  echo -e "|                                          |"
  echo -e "| ${BOLD}---- StintCoin linux wallet installer ----${NONE} |"
  echo -e "|                                          |"
  echo -e "--------------------------------------------"
  echo
  echo -e "${BOLD}"
  read -p "This script will install a StintCoin linux wallet on your VPS. Do you wish to continue? (y/n): " response
  echo -e "${NONE}"

  echo "[1/${STEPS}] Checking version..."
  if [[ $(lsb_release -d) < *16.04* ]]; then
    echo -e "${RED}You are not running Ubuntu 16.04 or higher. Installation is cancelled.${NONE}"
    exit 1
  fi

  if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}$0 must be run as root.${NONE}"
    exit 1
  fi
  echo -e "${GREEN}* Done${NONE}"

  if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
   echo -e "[2/${STEPS}] Preparing the system to install ${GREEN}$COIN_NAME${NONE} linux wallet...."
   apt-get update >/dev/null 2>&1
   DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
   DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
   apt install -y software-properties-common >/dev/null 2>&1
   echo -e "${GREEN}* Done${NONE}"
   echo -e "[3/${STEPS}] Adding bitcoin PPA repository."
   apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
   echo -e "${GREEN}* Done${NONE}"
   echo -e "[4/${STEPS}] Installing required packages, it may take some time to finish."
   apt-get update >/dev/null 2>&1
   apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev  libdb5.3++ unzip libzmq5 >/dev/null 2>&1
  fi

  if [ "$?" -gt "0" ]; then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NONE}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev libdb5.3++ unzip libzmq5"
    exit 1
  fi
  echo -e "${GREEN}* Done${NONE}"
}

function downloadNode() {
    echo -e "[5/${STEPS}] Downloading linux wallet..."
    cd $TMP_FOLDER >/dev/null 2>&1
    wget -q $COIN_TGZ
    chmod 755 $COIN_DAEMON $COIN_CLI > /dev/null 2>&1
    echo -e "${GREEN}* Done${NONE}"
}

function installNode() {
  echo -e "[6/${STEPS}] Installing linux wallet..."
  tar xvzf $COIN_ZIP --strip 2 >/dev/null 2>&1
  chmod +x $COIN_DAEMON $COIN_CLI
  cp $COIN_DAEMON $COIN_CLI $COIN_PATH
  cd - >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  cd
  echo -e "${GREEN}* Done${NONE}"
}

function installFail2ban() {
    echo -e "[7/${STEPS}] Installing fail2ban..."
    sudo apt-get -y install fail2ban > /dev/null 2>&1
    sudo systemctl enable fail2ban > /dev/null 2>&1
    sudo systemctl start fail2ban > /dev/null 2>&1
    echo -e "${GREEN}* Done${NONE}"
}

function installFirewall() {
    echo -e "[8/${STEPS}] Installing firewall..."
    sudo apt-get -y install ufw > /dev/null 2>&1
    sudo ufw allow OpenSSH > /dev/null 2>&1
    sudo ufw allow $COIN_PORT comment "$COIN_NAME port" > /dev/null 2>&1
    sudo ufw allow $RPC_PORT "$COIN_NAME rpcport" > /dev/null 2>&1
    echo "y" | sudo ufw enable > /dev/null 2>&1
    echo -e "${GREEN}* Done${NONE}"
}


function configureNode() {
    echo -e "[9/${STEPS}] Configuring linux wallet..."
    $COIN_PATH$COIN_DAEMON -daemon > /dev/null 2>&1
    sleep 5
    $COIN_PATH$COIN_CLI stop > /dev/null 2>&1
    sleep 5

    mnip=$(curl --silent ipinfo.io/ip)
    rpcuser=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    rpcpass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    port=$(echo "$COIN_PORT")
    rpcport=$(echo "$RPC_PORT")
    echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcallowip=127.0.0.1\nserver=1\ndaemon=1\nlogtimestamps=1\nmaxconnections=256" > $CONFIGFOLDER$CONFIG_FILE

    echo -e "${GREEN}* Done${NONE}"
    sleep 5
}

function startNode() {
    echo -e "[10/${STEPS}] Starting linux wallet..."
    $COIN_DAEMON > /dev/null 2>&1
    sleep 5
    echo -e "${GREEN}* Done${NONE}"
}

function importantInformation() {
 echo
 echo -e "==========================================================="
 echo -e "$COIN_NAME linux wallet is up and running"
 echo -e "Configuration file is: ${GREEN}$CONFIGFOLDER$CONFIG_FILE${NONE}"
 echo -e "Use ${GREEN}$COIN_CLI getblockcount to check your blockcount."
 echo -e "==========================================================="
}

function setupNode() {
  downloadNode
  installNode
  installFail2ban
  installFirewall
  configureNode
  startNode
  importantInformation
}


##### Main #####
prepareSystem
setupNode
