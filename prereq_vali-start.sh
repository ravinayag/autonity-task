#/usr/bin/bash


# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
#check & set  Aut execution Path
function Aut() {
    if [ -f "$HOME/.local/bin/aut" ]; then
        echo "Found the file  and setting into the PATH "
        AUT_PATH=$HOME/.local/bin
        PATH=$AUT_PATH:$PATH
        export AUT_BIN=$AUT_PATH/aut
        $AUT_BIN version
    elif
        read -p "Enter the Full path of aut file that located (ex. /usr/bin): " AUT_PATH
        echo "You entered $AUT_PATH"
        PATH=$AUT_PATH:$PATH
        export AUT_BIN=$AUT_PATH/aut
    then
        export AUT_BIN=$AUT_PATH/aut
        echo $AUT_BIN $AUT_PATH
    else
        echo "unable to find the aut command, Kindly  install it from github"
    fi
}

#Check & set Autonity execution Path
function Autonity() {
    if [ -f "$HOME/build/bin/autonity" ]; then
        echo "Found the file  and setting into the PATH "
        AUTONITY_PATH=$HOME/build/bin
        PATH=$AUTONITY_PATH:$PATH
        export AUTONITY_BIN=$AUTONITY_PATH/autonity
        $AUTONITY_BIN version
    elif
        read -p "Enter the Full path of autonity file that located (ex. /usr/bin): " AUTONITY_PATH
        echo "You entered $AUTONITY_PATH"
        PATH=$AUTONITY_PATH:$PATH
        export AUTONITY_BIN=$AUTONITY_PATH/autonity
    then
        export AUTONITY_BIN=$AUTONITY_PATH/autonity
        echo $AUTONITY_BIN $AUTONITY_PATH
    else
        echo "unable to find the autonity command, Kindly do install it from github"
    fi
}



#Check & set pipx, python3.9 
function pypipx() {
    if [ -f "$HOME/.local/bin/pipx" ]; then
        echo "Found the pipx and version is, `pipx --version`"
    else
        echo "No  pipx found in the path, checking for Python version..."
        pyver=$(python3 -V 2>&1 | sed 's/.* \([0-9]\).\([0-9]\).*/\1\2/')
        if [ "$pyver" -lt "39" ]; then     
            echo "Found lower version of python and This aut requires python >= 3.9  and pipx >= 0.16 ";  
            echo "Please Install/upgrade python , pipx versions"
        fi
    fi

}

# check &  set docker,docker-compose
function Doccheck() {
    dockerver=$(docker-compose version 2>&1 |grep  docker-compose | awk '{print $3}' | tr -d ., | head -c3)
    echo $dockerver
    if [[ "$dockerver" == *"not"* ]]; then
        echo "docker-compose not installed, please install first"
    elif [ "$dockerver" -lt "120" ]; then     
        echo "Docker compose version is `echo $dockerver` too low. Install/upgrade to recent, atleast >= 1.20 version"
    else
        echo "Good to proceed as docker & docker-compose  is gt v1.20 "     
    fi
}


#Check the pre requirements availability.
pypipx
Doccheck
Aut
Autonity

# Stage #2, Ensure you have ports open for trouble free communications to say "hello world"


#Download docker compose file

curl -sSLO https://raw.githubusercontent.com/ravinayag/autonity-task/master/docker-compose.yml


# Stage #2, Ensure you have ports open for trouble free communications to say "hello world"
# Ref. Look at the ports in docker-compose file.
# Assuming you have installed aut, autoninty, python+pipx, docker-compose binaries as part of pre-requisties. 

# Get Public IP
MYIP=$(curl ifconfig.me)

#update your public_ip
sed -i -e 's/{IP}/'$MYIP'/g' docker-compose.yml

# Start the Docker container
docker-compose -f docker-compose up -d 

#Once the prequresties are sucessfully installed,  assuming you have  configured the .autrc and  created wallet using aut command. 
#.autrc 

# Get Wallet Address
WALLET_ADDR="0x9838bd34711FF155A1E025724db3C83177919efc"

#Get ENODE URL Address
ENODEURL=$(aut node info -r http://127.0.0.1:8545 | grep enode | awk '{print $2}' | tr -d ,'"')
echo $ENODEURL

#Get the signature Address 
SIGN_ADDR=$($AUTONITY_PATH/autonity genEnodeProof --nodekey autonity-chaindata/autonity/nodekey $WALLET_ADDR | awk '{print $3}')
echo "Signature Address: " $SIGN_ADDR

#Get Compute Address
COMPU_ADDR=$(aut validator compute-address $ENODEURL)
echo "Compute Address: " $COMPU_ADDR

#Register your Node as validator
REGS_VALI=$(aut validator register $ENODEURL $SIGN_ADDR | aut tx sign - | aut tx send -)
echo "Validator Registration TX : " $REGS_VALI

#Check the Registration status
REGS_VALI_STAT=$(aut tx wait $REGS_VALI)
echo "Checking the Registration Status: "$REGS_VALI_STAT | jq

#Check Wallet balance
aut account balance $WALLET_ADDR

#check Validator
aut validator list | grep $COMPU_ADDR

#Validator info
aut validator info --validator $COMPU_ADDR

#stake bonding.
read -p "Enter the NTN VALUE to stake bonding : " NTN_VALUE
STAKE_TX=$(aut validator bond --validator $COMPU_ADDR $NTN_VALUE | aut tx sign - | aut tx send -)
echo "Stake TX : " $STAKE_TX

#check part for committee, it takes time to reflect.
aut protocol get-committee
