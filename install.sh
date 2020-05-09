#!/bin/bash
#  ███╗   ██╗ ██████╗ ██████╗ ███████╗███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗
#  ████╗  ██║██╔═══██╗██╔══██╗██╔════╝████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗
#  ██╔██╗ ██║██║   ██║██║  ██║█████╗  ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝
#  ██║╚██╗██║██║   ██║██║  ██║██╔══╝  ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗
#  ██║ ╚████║╚██████╔╝██████╔╝███████╗██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║
#  ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
#                                                              ╚╗ @marsmensch 2016-2018 ╔╝                   				
#                   
# version 	v0.9.4
# date    	2018-04-04
#
# function:	part of the masternode scripts, source the proper config file
#
# 	Instructions:
#               Run this script w/ the desired parameters. Leave blank or use -h for help.
#
#	Platforms:
#               - Linux Ubuntu 16.04 LTS ONLY on a Vultr, Hetzner or DigitalOcean VPS
#               - Generic Ubuntu support will be added at a later point in time
#
# Twitter 	@marsmensch

# Useful variables
declare -r CRYPTOS=`ls -l config/ | egrep '^d' | awk '{print $9}' | xargs echo -n; echo`
declare -r DATE_STAMP="$(date +%y-%m-%d-%s)"
declare -r SCRIPTPATH=$( cd $(dirname ${BASH_SOURCE[0]}) > /dev/null; pwd -P )
declare -r MASTERPATH="$(dirname "${SCRIPTPATH}")"
declare -r SCRIPT_VERSION="v0.9.4"
declare -r SCRIPT_LOGFILE="/tmp/nodemaster_${DATE_STAMP}_out.log"
declare -r IPV4_DOC_LINK="https://www.vultr.com/docs/add-secondary-ipv4-address"
declare -r DO_NET_CONF="/etc/network/interfaces.d/50-cloud-init.cfg"

function showbanner() {
cat << "EOF"
 ███╗   ██╗ ██████╗ ██████╗ ███████╗███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗
 ████╗  ██║██╔═══██╗██╔══██╗██╔════╝████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗
 ██╔██╗ ██║██║   ██║██║  ██║█████╗  ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝
 ██║╚██╗██║██║   ██║██║  ██║██╔══╝  ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗
 ██║ ╚████║╚██████╔╝██████╔╝███████╗██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║
 ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
                                                             ╚╗ @marsmensch 2016-2018 ╔╝
EOF
}

# /*
# confirmation message as optional parameter, asks for confirmation
# get_confirmation && COMMAND_TO_RUN or prepend a message
# */
#
function get_confirmation() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

#
# /* no parameters, displays the help message */
#
function show_help(){
    clear
    showbanner
    echo "install.sh, version $SCRIPT_VERSION";
    echo "Usage example:";
    echo "install.sh (-p|--project) string [(-h|--help)] [(-n|--net) int] [(-c|--count) int] [(-r|--release) string] [(-w|--wipe)] [(-u|--update)] [(-x|--startnodes)]";
    echo "Options:";
    echo "-h or --help: Displays this information.";
    echo "-p or --project string: Project to be installed. REQUIRED.";
    echo "-n or --net: IP address type t be used (4 vs. 6).";
    echo "-c or --count: Number of masternodes to be installed.";
    echo "-r or --release: Release version to be installed.";
    echo "-s or --sentinel: Add sentinel monitoring for a node type. Combine with the -p option";
    echo "-w or --wipe: Wipe ALL local data for a node type. Combine with the -p option";
    echo "-u or --update: Update a specific masternode daemon. Combine with the -p option";
    echo "-r or --release: Release version to be installed.";
	echo "-x or --startnodes: Start masternodes after installation to sync with blockchain";
    exit 1;
}

#
# /* no parameters, checks if we are running on a supported Ubuntu release */
#
function check_distro() {
	# currently only for Ubuntu 16.04
	if [[ -r /etc/os-release ]]; then
		. /etc/os-release
		if [[ "${VERSION_ID}" != "16.04" ]]; then
			echo "This script only supports ubuntu 16.04 LTS, exiting."
			exit 1
		fi
	else
		# no, thats not ok!
		echo "This script only supports ubuntu 16.04 LTS, exiting."
		exit 1
	fi
}

#
# /* no parameters, installs the base set of packages that are required for all projects */
#
function install_packages() {
	# development and build packages
	# these are common on all cryptos
	echo "* Package installation!"
	apt-get -qq -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true update
	apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install build-essential g++ \
	protobuf-compiler libboost-all-dev autotools-dev \
    automake libcurl4-openssl-dev libboost-all-dev libssl-dev libdb++-dev \
    make autoconf automake libtool git apt-utils libprotobuf-dev pkg-config \
    libcurl3-dev libudev-dev libqrencode-dev bsdmainutils pkg-config libssl-dev \
    libgmp3-dev libevent-dev jp2a pv virtualenv	&>> ${SCRIPT_LOGFILE}
}

#
# /* no parameters, creates and activates a swapfile since VPS servers often do not have enough RAM for compilation */
#
function swaphack() {
#check if swap is available
if [ $(free | awk '/^Swap:/ {exit !$2}') ] || [ ! -f "/var/mnode_swap.img" ];then
	echo "* No proper swap, creating it"
	# needed because ant servers are ants
	rm -f /var/mnode_swap.img
	dd if=/dev/zero of=/var/mnode_swap.img bs=1024k count=${MNODE_SWAPSIZE} &>> ${SCRIPT_LOGFILE}
	chmod 0600 /var/mnode_swap.img
	mkswap /var/mnode_swap.img &>> ${SCRIPT_LOGFILE}
	swapon /var/mnode_swap.img &>> ${SCRIPT_LOGFILE}
	echo '/var/mnode_swap.img none swap sw 0 0' | tee -a /etc/fstab &>> ${SCRIPT_LOGFILE}
	echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf               &>> ${SCRIPT_LOGFILE}
	echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf		&>> ${SCRIPT_LOGFILE}
else
	echo "* All good, we have a swap"
fi
}

#
# /* no parameters, creates and activates a dedicated masternode user */
#
function create_mn_user() {

    # our new mnode unpriv user acc is added
    if id "${MNODE_USER}" >/dev/null 2>&1; then
        echo "user exists already, do nothing" &>> ${SCRIPT_LOGFILE}
    else
        echo "Adding new system user ${MNODE_USER}"
        adduser --disabled-password --gecos "" ${MNODE_USER} &>> ${SCRIPT_LOGFILE}
    fi

}

#
# /* no parameters, creates a masternode data directory (one per masternode)  */
#
function create_mn_dirs() {

    # individual data dirs for now to avoid problems
    echo "* Creating masternode directories"
    mkdir -p ${MNODE_CONF_BASE}
	for NUM in $(seq 1 ${count}); do
	    if [ ! -d "${MNODE_DATA_BASE}/${CODENAME}${NUM}" ]; then
	         echo "creating data directory ${MNODE_DATA_BASE}/${CODENAME}${NUM}" &>> ${SCRIPT_LOGFILE}
             mkdir -p ${MNODE_DATA_BASE}/${CODENAME}${NUM} &>> ${SCRIPT_LOGFILE}
        fi
	done

}

#
# /* no parameters, creates a sentinel config for a set of masternodes (one per masternode)  */
#
function create_sentinel_setup() {

	# if code directory does not exists, we create it clone the src
	if [ ! -d /usr/share/sentinel ]; then
		cd /usr/share                                               &>> ${SCRIPT_LOGFILE}
		git clone https://github.com/dashpay/sentinel.git sentinel  &>> ${SCRIPT_LOGFILE}
		cd sentinel                                                 &>> ${SCRIPT_LOGFILE}
		rm -f rm sentinel.conf                                      &>> ${SCRIPT_LOGFILE}
	else
		echo "* Updating the existing sentinel GIT repo"
		cd /usr/share/sentinel        &>> ${SCRIPT_LOGFILE}
		git pull                      &>> ${SCRIPT_LOGFILE}
		rm -f rm sentinel.conf        &>> ${SCRIPT_LOGFILE}
	fi

	# create a globally accessible venv and install sentinel requirements
	virtualenv --system-site-packages /usr/share/sentinelvenv      &>> ${SCRIPT_LOGFILE}
	/usr/share/sentinelvenv/bin/pip install -r requirements.txt    &>> ${SCRIPT_LOGFILE}

    # create one sentinel config file per masternode
	for NUM in $(seq 1 ${count}); do
	    if [ ! -f "/usr/share/sentinel/${CODENAME}${NUM}_sentinel.conf" ]; then
	         echo "* Creating sentinel configuration for ${CODENAME} masternode number ${NUM}" &>> ${SCRIPT_LOGFILE}
		     echo "dash_conf=${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf"   > /usr/share/sentinel/${CODENAME}${NUM}_sentinel.conf
             echo "network=mainnet"                                         >> /usr/share/sentinel/${CODENAME}${NUM}_sentinel.conf
             echo "db_name=database/${CODENAME}_${NUM}_sentinel.db"         >> /usr/share/sentinel/${CODENAME}${NUM}_sentinel.conf
             echo "db_driver=sqlite"                                        >> /usr/share/sentinel/${CODENAME}${NUM}_sentinel.conf
        fi
	done

    echo "Generated a Sentinel config for you. To activate Sentinel run"
    echo "export SENTINEL_CONFIG=${MNODE_CONF_BASE}/${CODENAME}${NUM}_sentinel.conf; /usr/share/sentinelvenv/bin/python /usr/share/sentinel/bin/sentinel.py"
    echo ""
    echo "If it works, add the command as cronjob:  "
    echo "* * * * * export SENTINEL_CONFIG=${MNODE_CONF_BASE}/${CODENAME}${NUM}_sentinel.conf; /usr/share/sentinelvenv/bin/python /usr/share/sentinel/bin/sentinel.py 2>&1 >> /var/log/sentinel/sentinel-cron.log"

}

#
# /* no parameters, creates a minimal set of firewall rules that allows INBOUND masternode p2p & SSH ports */
#
function configure_firewall() {

    echo "* Configuring firewall rules"
	# disallow everything except ssh and masternode inbound ports
	ufw default deny                          &>> ${SCRIPT_LOGFILE}
	ufw logging on                            &>> ${SCRIPT_LOGFILE}
	ufw allow ${SSH_INBOUND_PORT}/tcp         &>> ${SCRIPT_LOGFILE}
	# KISS, its always the same port for all interfaces
	ufw allow ${MNODE_INBOUND_PORT}/tcp       &>> ${SCRIPT_LOGFILE}
	# This will only allow 6 connections every 30 seconds from the same IP address.
	ufw limit OpenSSH	                      &>> ${SCRIPT_LOGFILE}
	ufw --force enable                        &>> ${SCRIPT_LOGFILE}
	echo "* Firewall ufw is active and enabled on system startup"

}

#
# /* no parameters, checks if the choice of networking matches w/ this VPS installation */
#
function validate_netchoice() {

    echo "* Validating network rules"

	# break here of net isn't 4 or 6
	if [ ${net} -ne 4 ] && [ ${net} -ne 6 ]; then
		echo "invalid NETWORK setting, can only be 4 or 6!"
		exit 1;
	fi

	# generate the required ipv6 config
	if [ "${net}" -eq 4 ]; then
	    IPV6_INT_BASE="#NEW_IPv4_ADDRESS_FOR_MASTERNODE_NUMBER"
	    NETWORK_BASE_TAG=""
        echo "IPv4 address generation needs to be done manually atm!"  &>> ${SCRIPT_LOGFILE}
	fi	# end ifneteq4

}

#
# /* no parameters, generates one masternode configuration file per masternode in the default
#    directory (eg. /etc/masternodes/${CODENAME} and replaces the existing placeholders if possible */
#
function create_mn_configuration() {

        # always return to the script root
        cd ${SCRIPTPATH}
        for NUM in $(seq 1 ${count}); do
          if [ -n "${PRIVKEY[${NUM}]}" ]; then
            echo ${PRIVKEY[${NUM}]} >> tmp.txt
          fi
        done
        if [ -f tmp.txt ]; then
            dup=$(sort -t 8 tmp.txt | uniq -c | sort -nr | head -1 | awk '{print substr($0, 7, 1)}')
            if [ 1 -ne "$dup" ]; then
                echo "Private key was duplicated. Please restart this script."
                rm -r /etc/masternodes
                rm tmp.txt
                exit 1
            fi
            rm tmp.txt
        fi

        # create one config file per masternode
        for NUM in $(seq 1 ${count}); do
        PASS=$(date | md5sum | cut -c1-24)

	# we dont want to overwrite an existing config file
	if [ ! -f ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf ]; then
        	echo "individual masternode config doesn't exist, generate it!"                  &>> ${SCRIPT_LOGFILE}
		# if a template exists, use this instead of the default
		if [ -e config/${CODENAME}/${CODENAME}.conf ]; then
			echo "custom configuration template for ${CODENAME} found, use this instead"                      &>> ${SCRIPT_LOGFILE}
			cp ${SCRIPTPATH}/config/${CODENAME}/${CODENAME}.conf ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf  &>> ${SCRIPT_LOGFILE}
		else
			echo "No ${CODENAME} template found, using the default configuration template"			          &>> ${SCRIPT_LOGFILE}
			cp ${SCRIPTPATH}/config/default.conf ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf                  &>> ${SCRIPT_LOGFILE}
		fi
		# replace placeholders
		echo "running sed on file ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf"                                &>> ${SCRIPT_LOGFILE}
	fi
	
        if [ -n "${PRIVKEY[${NUM}]}" ]; then
        	if [ ${#PRIVKEY[${NUM}]} -eq 51 ]; then
        		sed -e "s/HERE_GOES_YOUR_MASTERNODE_KEY_FOR_MASTERNODE_XXX_GIT_PROJECT_XXX_XXX_NUM_XXX/${PRIVKEY[${NUM}]}/" -i ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf
          	else
            		echo "input private key ${PRIVKEY[${NUM}]} was invalid. Please check the key, and restart this script."
            		rm -r /etc/masternodes
            		exit 1
          	fi
        else :
        fi
        sed -e "s/XXX_GIT_PROJECT_XXX/${CODENAME}/" -e "s/XXX_NUM_XXY/${NUM}]/" -e "s/XXX_NUM_XXX/${NUM}/" -e "s/XXX_PASS_XXX/${PASS}/" -e "s/XXX_IPV6_INT_BASE_XXX/[${IPV6_INT_BASE}/" -e "s/XXX_NETWORK_BASE_TAG_XXX/${NETWORK_BASE_TAG}/" -e "s/XXX_MNODE_INBOUND_PORT_XXX/${MNODE_INBOUND_PORT}/" -i ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf
	if [ -z "${PRIVKEY[${NUM}]}" ]; then
		if [ "$startnodes" -eq 1 ]; then
			#uncomment masternode= and masternodeprivkey= so the node can autostart and sync
			sed 's/\(^.*masternode\(\|privkey\)=.*$\)/#\1/' -i ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf
		fi
	fi
        done
}

#
# /* no parameters, generates a masternode configuration file per masternode in the default */
#
function create_control_configuration() {
    	# delete any old stuff that's still around
    	rm -f /tmp/${CODENAME}_masternode.conf &>> ${SCRIPT_LOGFILE}
	# create one line per masternode with the data we have
	for NUM in $(seq 1 ${count}); do
		if [ -n "${PRIVKEY[${NUM}]}" ]; then
    			echo ${CODENAME}MN${NUM} [${IPV6_INT_BASE}:${NETWORK_BASE_TAG}::${NUM}]:${MNODE_INBOUND_PORT} ${PRIVKEY[${NUM}]} COLLATERAL_TX_FOR_${CODENAME}MN${NUM} OUTPUT_NO_FOR_${CODENAME}MN${NUM} >> /tmp/${CODENAME}_masternode.conf
    		else
			echo ${CODENAME}MN${NUM} [${IPV6_INT_BASE}:${NETWORK_BASE_TAG}::${NUM}]:${MNODE_INBOUND_PORT} MASTERNODE_PRIVKEY_FOR_${CODENAME}MN${NUM} COLLATERAL_TX_FOR_${CODENAME}MN${NUM} OUTPUT_NO_FOR_${CODENAME}MN${NUM} >> /tmp/${CODENAME}_masternode.conf
		fi
	done
}

#
# /* no parameters, generates a a pre-populated masternode systemd config file */
#
function create_systemd_configuration() {

    echo "* (over)writing systemd config files for masternodes"
	# create one config file per masternode
	for NUM in $(seq 1 ${count}); do
	PASS=$(date | md5sum | cut -c1-24)
		echo "* (over)writing systemd config file ${SYSTEMD_CONF}/${CODENAME}_n${NUM}.service"  &>> ${SCRIPT_LOGFILE}
		cat > ${SYSTEMD_CONF}/${CODENAME}_n${NUM}.service <<-EOF
			[Unit]
			Description=${CODENAME} distributed currency daemon
			After=network.target

			[Service]
			User=${MNODE_USER}
			Group=${MNODE_USER}

			Type=forking
			PIDFile=${MNODE_DATA_BASE}/${CODENAME}${NUM}/${CODENAME}.pid
			ExecStart=${MNODE_DAEMON} -daemon -pid=${MNODE_DATA_BASE}/${CODENAME}${NUM}/${CODENAME}.pid \
			-conf=${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf -datadir=${MNODE_DATA_BASE}/${CODENAME}${NUM}

			Restart=always
			RestartSec=5
			PrivateTmp=true
			TimeoutStopSec=60s
			TimeoutStartSec=5s
			StartLimitInterval=120s
			StartLimitBurst=15

			[Install]
			WantedBy=multi-user.target
		EOF
	done

}

#
# /* set all permissions to the masternode user */
#
function set_permissions() {

	# maybe add a sudoers entry later
	chown -R ${MNODE_USER}:${MNODE_USER} ${MNODE_CONF_BASE} ${MNODE_DATA_BASE} /var/log/sentinel &>> ${SCRIPT_LOGFILE}
	# make group permissions same as user, so vps-user can be added to masternode group
	chmod -R g=u ${MNODE_CONF_BASE} ${MNODE_DATA_BASE} /var/log/sentinel &>> ${SCRIPT_LOGFILE}

}

#
# /* wipe all files and folders generated by the script for a specific project */
#
function wipe_all() {

    	echo "Deleting all ${project} related data!"
	rm -f /etc/masternodes/${project}_n*.conf
	rmdir --ignore-fail-on-non-empty -p /var/lib/masternodes/${project}*
	rm -f /etc/systemd/system/${project}_n*.service
	rm -f ${MNODE_DAEMON}
	echo "DONE!"
	exit 0

}

#
#Generate masternode private key
#
function generate_privkey() {
	echo -e "rpcuser=test\nrpcpassword=passtest" >> ${MNODE_CONF_BASE}/${CODENAME}_test.conf
  	mkdir -p ${MNODE_DATA_BASE}/${CODENAME}_test
  	phored -daemon -conf=${MNODE_CONF_BASE}/${CODENAME}_test.conf -datadir=${MNODE_DATA_BASE}/${CODENAME}_test
  	sleep 5
  	
	for NUM in $(seq 1 ${count}); do
    		if [ -z "${PRIVKEY[${NUM}]}" ]; then
    			PRIVKEY[${NUM}]=$(phore-cli -conf=${MNODE_CONF_BASE}/${CODENAME}_test.conf -datadir=${MNODE_DATA_BASE}/${CODENAME}_test masternode genkey)
    		fi
  	done
  	phore-cli -conf=${MNODE_CONF_BASE}/${CODENAME}_test.conf -datadir=${MNODE_DATA_BASE}/${CODENAME}_test stop
  	sleep 5
  	rm -r ${MNODE_CONF_BASE}/${CODENAME}_test.conf ${MNODE_DATA_BASE}/${CODENAME}_test
}

#
# /*
# remove packages and stuff we don't need anymore and set some recommended
# kernel parameters
# */
#
function cleanup_after() {

	apt-get -qqy -o=Dpkg::Use-Pty=0 --force-yes autoremove
	apt-get -qqy -o=Dpkg::Use-Pty=0 --force-yes autoclean

	echo "kernel.randomize_va_space=1" > /etc/sysctl.conf  &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.conf.all.rp_filter=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.conf.all.accept_source_route=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.icmp_echo_ignore_broadcasts=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.conf.all.log_martians=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.conf.default.log_martians=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.conf.all.accept_redirects=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv6.conf.all.accept_redirects=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.conf.all.send_redirects=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "kernel.sysrq=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.tcp_timestamps=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.icmp_ignore_bogus_error_responses=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	sysctl -p

}

#
# /* project as parameter, sources the project specific parameters and runs the main logic */
#

# source the default and desired crypto configuration files
function source_config() {

    SETUP_CONF_FILE="${SCRIPTPATH}/config/${project}/${project}.env"

    # first things first, to break early if things are missing or weird
    check_distro

	if [ -f ${SETUP_CONF_FILE} ]; then
		echo "Script version ${SCRIPT_VERSION}, you picked: ${project}"
		echo "apply config file for ${project}"	&>> ${SCRIPT_LOGFILE}
		source "${SETUP_CONF_FILE}"

		# count is from the default config but can ultimately be
		# overwritten at runtime
		if [ -z "${count}" ]
		then
			count=${SETUP_MNODES_COUNT}
			echo "No number given, installing default number of nodes: ${SETUP_MNODES_COUNT}" &>> ${SCRIPT_LOGFILE}
		fi

		# release is from the default project config but can ultimately be
		# overwritten at runtime
		if [ -z "$release" ]
		then
			release=${SCVERSION}
			echo "release empty, setting to project default: ${SCVERSION}"  &>> ${SCRIPT_LOGFILE}
		fi

		# net is from the default config but can ultimately be
		# overwritten at runtime
		if [ -z "${net}" ]; then
			net=${NETWORK_TYPE}
			echo "net EMPTY, setting to default: ${NETWORK_TYPE}" &>> ${SCRIPT_LOGFILE}
		fi

		# main block of function logic starts here
	    	# if update flag was given, delete the old daemon binary first & proceed
		if [ "$update" -eq 1 ]; then
			echo "update given, deleting the old daemon NOW!" &>> ${SCRIPT_LOGFILE}
			rm -f ${MNODE_DAEMON}
		fi

		echo "************************* Installation Plan *****************************************"
		echo ""
		echo "I am going to install and configure "
       		echo "=> ${count} ${project} masternode(s) in version ${release}"
        	echo "for you now."
        	echo ""
		echo "You have to add your masternode private key to the individual config files afterwards"
		echo ""
		echo "Stay tuned!"
        	echo ""
		# show a hint for MANUAL IPv4 configuration
		if [ "${net}" -eq 4 ]; then
			NETWORK_TYPE=4
			echo "WARNING:"
			echo "You selected IPv4 for networking but there is no automatic workflow for this part."
			echo "This means you will have some mamual work to do to after this configuration run."
			echo ""
			echo "See the following link for instructions how to add multiple ipv4 addresses on vultr:"
			echo "${IPV4_DOC_LINK}"
		fi
		# sentinel setup
		if [ "$sentinel" -eq 1 ]; then
			echo "I will also generate a Sentinel configuration for you."
		fi
		# start nodes after setup
		if [ "$startnodes" -eq 1 ]; then
			echo "I will start your masternodes after the installation."
		fi
		echo ""
		echo "A logfile for this run can be found at the following location:"
		echo "${SCRIPT_LOGFILE}"
		echo ""
		echo "*************************************************************************************"
		sleep 5

		# main routine
		print_logo
        	prepare_mn_interfaces
        	swaphack
        	install_packages
		build_mn_from_source
		create_mn_user
		create_mn_dirs
	
    		# private key initialize
    		if [ "$generate" -eq 1 ]; then
      			echo "Generating masternode private key" &>> ${SCRIPT_LOGFILE}
      			generate_privkey
		fi
	
		# sentinel setup
		if [ "$sentinel" -eq 1 ]; then
			echo "* Sentinel setup chosen" &>> ${SCRIPT_LOGFILE}
			create_sentinel_setup
		fi
	
		configure_firewall
		create_mn_configuration
		create_control_configuration
		create_systemd_configuration
		set_permissions
		cleanup_after
		showbanner
		final_call
	else
		echo "required file ${SETUP_CONF_FILE} does not exist, abort!"
		exit 1
	fi

}

function print_logo() {

	# print ascii banner if a logo exists
	echo -e "* Starting the compilation process for ${CODENAME}, stay tuned"
	if [ -f "${SCRIPTPATH}/assets/$CODENAME.jpg" ]; then
			jp2a -b --colors --width=56 ${SCRIPTPATH}/assets/${CODENAME}.jpg
	else
			jp2a -b --colors --width=56 ${SCRIPTPATH}/assets/default.jpg          
	fi  

}

#
# /* no parameters, builds the required masternode binary from sources. Exits if already exists and "update" not given  */
#
function build_mn_from_source() {
        # daemon not found compile it
        if [ ! -f ${MNODE_DAEMON} ]; then
                mkdir -p ${SCRIPTPATH}/${CODE_DIR} &>> ${SCRIPT_LOGFILE}
                # if code directory does not exists, we create it clone the src
                if [ ! -d ${SCRIPTPATH}/${CODE_DIR}/${CODENAME} ]; then
                        mkdir -p ${CODE_DIR} && cd ${SCRIPTPATH}/${CODE_DIR} &>> ${SCRIPT_LOGFILE}
                        git clone ${GIT_URL} ${CODENAME}          &>> ${SCRIPT_LOGFILE}
                        cd ${SCRIPTPATH}/${CODE_DIR}/${CODENAME}  &>> ${SCRIPT_LOGFILE}
                        echo "* Checking out desired GIT tag: ${release}"
                        git checkout ${release}                   &>> ${SCRIPT_LOGFILE}
                else
                        echo "* Updating the existing GIT repo"
                        cd ${SCRIPTPATH}/${CODE_DIR}/${CODENAME}  &>> ${SCRIPT_LOGFILE}
                        git pull                                  &>> ${SCRIPT_LOGFILE}
                        echo "* Checking out desired GIT tag: ${release}"
                        git checkout ${release}                   &>> ${SCRIPT_LOGFILE}
                fi

                # print ascii banner if a logo exists
                echo -e "* Starting the compilation process for ${CODENAME}, stay tuned"
                if [ -f "${SCRIPTPATH}/assets/$CODENAME.jpg" ]; then
                        jp2a -b --colors --width=56 ${SCRIPTPATH}/assets/${CODENAME}.jpg
                else
                        jp2a -b --colors --width=56 ${SCRIPTPATH}/assets/default.jpg
                fi
                # compilation starts here
                source ${SCRIPTPATH}/config/${CODENAME}/${CODENAME}.compile | pv -t -i0.1
        else
                echo "* Daemon already in place at ${MNODE_DAEMON}, not compiling"
        fi

		# if it's not available after compilation, theres something wrong
        if [ ! -f ${MNODE_DAEMON} ]; then
                echo "COMPILATION FAILED! Please open an issue at https://github.com/masternodes/vps/issues. Thank you!"
                exit 1
        fi
}

#
# /* no parameters, print some (hopefully) helpful advice  */
#
function final_call() {
	# note outstanding tasks that need manual work
    echo "************! ALMOST DONE !******************************"
	echo "There is still work to do in the configuration templates."
	echo "These are located at ${MNODE_CONF_BASE}, one per masternode."
	echo "Add your masternode private keys now."
	echo "eg in /etc/masternodes/${CODENAME}_n1.conf"
	echo ""
    echo "=> All configuration files are in: ${MNODE_CONF_BASE}"
    echo "=> All Data directories are in: ${MNODE_DATA_BASE}"
	echo ""
	echo "last but not least, run /usr/local/bin/activate_masternodes_${CODENAME} as root to activate your nodes."

    # place future helper script accordingly
    cp ${SCRIPTPATH}/scripts/activate_masternodes.sh ${MNODE_HELPER}_${CODENAME}
	echo "">> ${MNODE_HELPER}_${CODENAME}

	for NUM in $(seq 1 ${count}); do
		echo "systemctl enable ${CODENAME}_n${NUM}" >> ${MNODE_HELPER}_${CODENAME}
		echo "systemctl restart ${CODENAME}_n${NUM}" >> ${MNODE_HELPER}_${CODENAME}
	done

	chmod u+x ${MNODE_HELPER}_${CODENAME}
	if [ "$startnodes" -eq 1 ]; then
		echo ""
		echo "** Your nodes are starting up. If you haven't set masternode private key, Don't forget to change the masternodeprivkey later."
		${MNODE_HELPER}_${CODENAME}
	fi
	tput sgr0
}

#
# /* no parameters, create the required network configuration. IPv6 is auto.  */
#
function prepare_mn_interfaces() {

    # this allows for more flexibility since every provider uses another default interface
    # current default is:
    # * ens3 (vultr) w/ a fallback to "eth0" (Hetzner, DO & Linode w/ IPv4 only)
    #

    # check for the default interface status
    if [ ! -f /sys/class/net/${ETH_INTERFACE}/operstate ]; then
        echo "Default interface doesn't exist, switching to eth0"
        export ETH_INTERFACE="eth0"
    fi

    # get the current interface state
    ETH_STATUS=$(cat /sys/class/net/${ETH_INTERFACE}/operstate)

    # check interface status
    if [[ "${ETH_STATUS}" = "down" ]] || [[ "${ETH_STATUS}" = "" ]]; then
        echo "Default interface is down, fallback didn't work. Break here."
        exit 1
    fi

    # DO ipv6 fix, are we on DO?
    # check for DO network config file
    if [ -f ${DO_NET_CONF} ]; then
        # found the DO config
		if ! grep -q "::8888" ${DO_NET_CONF}; then
			echo "ipv6 fix not found, applying!"
			sed -i '/iface eth0 inet6 static/a dns-nameservers 2001:4860:4860::8844 2001:4860:4860::8888 8.8.8.8 127.0.0.1' ${DO_NET_CONF}
			ifdown ${ETH_INTERFACE}; ifup ${ETH_INTERFACE};
		fi
    fi

    IPV6_INT_BASE="$(ip -6 addr show dev ${ETH_INTERFACE} | grep inet6 | awk -F '[ \t]+|/' '{print $3}' | grep -v ^fe80 | grep -v ^::1 | cut -f1-4 -d':' | head -1)" &>> ${SCRIPT_LOGFILE}

	validate_netchoice
	echo "IPV6_INT_BASE AFTER : ${IPV6_INT_BASE}" &>> ${SCRIPT_LOGFILE}

    # user opted for ipv6 (default), so we have to check for ipv6 support
	# check for vultr ipv6 box active
	if [ -z "${IPV6_INT_BASE}" ] && [ ${net} -ne 4 ]; then
		echo "No IPv6 support on the VPS but IPv6 is the setup default. Please switch to ipv4 with flag \"-n 4\" if you want to continue."
		echo ""
		echo "See the following link for instructions how to add multiple ipv4 addresses on vultr:"
		echo "${IPV4_DOC_LINK}"
		exit 1
	fi

	# generate the required ipv6 config
	if [ "${net}" -eq 6 ]; then
        # vultr specific, needed to work
	    sed -ie '/iface ${ETH_INTERFACE} inet6 auto/s/^/#/' ${NETWORK_CONFIG}

		# move current config out of the way first
		cp ${NETWORK_CONFIG} ${NETWORK_CONFIG}.${DATE_STAMP}.bkp

		# create the additional ipv6 interfaces, rc.local because it's more generic
		for NUM in $(seq 1 ${count}); do

			# check if the interfaces exist
			ip -6 addr | grep -qi "${IPV6_INT_BASE}:${NETWORK_BASE_TAG}::${NUM}"
			if [ $? -eq 0 ]
			then
			  echo "IP for masternode already exists, skipping creation" &>> ${SCRIPT_LOGFILE}
			else
			  echo "Creating new IP address for ${CODENAME} masternode nr ${NUM}" &>> ${SCRIPT_LOGFILE}
			  if [ "${NETWORK_CONFIG}" = "/etc/rc.local" ]; then
			    # need to put network config in front of "exit 0" in rc.local
				sed -e '$i ip -6 addr add '"${IPV6_INT_BASE}"':'"${NETWORK_BASE_TAG}"'::'"${NUM}"'/64 dev '"${ETH_INTERFACE}"'\n' -i ${NETWORK_CONFIG}
			  else
			    # if not using rc.local, append normally
			  	echo "ip -6 addr add ${IPV6_INT_BASE}:${NETWORK_BASE_TAG}::${NUM}/64 dev ${ETH_INTERFACE}" >> ${NETWORK_CONFIG}
			  fi
			  sleep 2
			  ip -6 addr add ${IPV6_INT_BASE}:${NETWORK_BASE_TAG}::${NUM}/64 dev ${ETH_INTERFACE} &>> ${SCRIPT_LOGFILE}
			fi
		done # end forloop
	fi # end ifneteq6

}

##################------------Menu()---------#####################################

# Declare vars. Flags initalizing to 0.
wipe=0;
debug=0;
update=0;
sentinel=0;
generate=0;
startnodes=0;

# Execute getopt
ARGS=$(getopt -o "hp:n:c:r:wsudxgk:k2:k3:k4:k5:k6:k7:k8:k9:k10:k11:k12:k13:k14:k15:k16:17:k18:k19:k20:k21:k22:k23:k24:k25:k26:k27:k28:k29:k30:k31:k32:k33:k34:k35:k36:k37:k38:k39:k40:k41:k42:k43:k44:k45:k46:k47:k48:k49:k50:k51:k52:k53:k54:k55:k56:k57:k58:k59:k60:k61:k62:k63:k64:k65:k66:k67:k68:k69:k70:k71:k72:k73:k74:k75:k76:k77:k78:k79:k80:k81:k82:k83:k84:k85:k86:k87:k88:k89:k90:k91:k92:k93:k94:k95:k96:k97:k98:k99:k100:k101:k102:k103:k104:k105:k106:k107:k108:k109:k110:k111:k112:k113:k114:k115:k116:k117:k118:k119:k120" -l "help,project:,net:,count:,release:,wipe,sentinel,update,debug,startnodes,generate,key:,key2:,key3:,key4:,key5:,key6:,key7:,key8:,key9:,key10:,key11:,key12:,key13:,key14:,key15:,key16:,key17:,key18:,key19:,key20:,key21:,key22:,key23:,key24:,key25:,key26:,key27:,key28:,key29:,key30:,key31:,key32:,key33:,key34:,key35:,key36:,key37:,key38:,key39:,key40:,key41:,key42:,key43:,key44:,key45:,key46:,key47:,key48:,key49:,key50:,key51:,key52:,key53:,key54:,key55:,key56:,key57:,key58:,key59:,key60:,key61:,key62:,key63:,key64:,key65:,key66:,key67:,key68:,key69:,key70:,key71:,key72:,key73:,key74:,key75:,key76:,key77:,key78:,key79:,key80:,key81:,key82:,key83:,key84:,key85:,key86:,key87:,key88:,key89:,key90:,key91:,key92:,key93:,key94:,key95:,key96:,key97:,key98:,key99:,key100:,key101:,key102:,key103:,key104:,key105:,key106:,key107:,key108:,key109:,key110:,key111:,key112:,key113:,key114:,key115:,key116:,key117:,key118:,key119:,key120:" -n "install.sh" -- "$@");

#Bad arguments
if [ $? -ne 0 ];
then
    help;
fi

eval set -- "$ARGS";

while true; do
    case "$1" in
        -h |--help)
            shift;
            help;
            ;;
        -p |--project)
            shift;
                    if [ -n "$1" ];
                    then
                        project="$1";
                        shift;
                    fi
            ;;
        -n |--net)
            shift;
                    if [ -n "$1" ];
                    then
                        net="$1";
                        shift;
                    fi
            ;;
        -c |--count)
            shift;
                    if [ -n "$1" ];
                    then
                        count="$1";
                        shift;
                    fi
            ;;
        -r |--release)
            shift;
                    if [ -n "$1" ];
                    then
                        release="$1";
                        SCVERSION="$1"
                        shift;
                    fi
            ;;
        -w |--wipe)
            shift;
                    wipe="1";
            ;;
        -s |--sentinel)
            shift;
                    sentinel="1";
            ;;
        -u |--update)
            shift;
                    update="1";
            ;;
        -d |--debug)
            shift;
                    debug="1";
            ;;
        -x|--startnodes)
            shift;
                    startnodes="1";
            ;;

        -g | --generate)
            shift;
                    generate="1";
            ;;
        -k |--key)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[1]="$1";
                        shift;
                    fi
            ;;
        -k2 |--key2)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[2]="$1";
                        shift;
                    fi
            ;;
        -k3 |--key3)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[3]="$1";
                        shift;
                    fi
            ;;
        -k4 |--key4)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[4]="$1";
                        shift;
                    fi
            ;;
        -k5 |--key5)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[5]="$1";
                        shift;
                    fi
            ;;
        -k6 |--key6)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[6]="$1";
                        shift;
                    fi
            ;;
        -k7 |--key7)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[7]="$1";
                        shift;
                    fi
            ;;
	      -k8 |--key8)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[8]="$1";
                        shift;
                    fi
            ;;
        -k9 |--key9)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[9]="$1";
                        shift;
                    fi
            ;;
	     -k10 |--key10)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[10]="$1";
                        shift;
                    fi
            ;;
				     -k11 |--key11)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[11]="$1";
                        shift;
                    fi
            ;;
				     -k12 |--key12)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[12]="$1";
                        shift;
                    fi
            ;;
				     -k13 |--key13)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[13]="$1";
                        shift;
                    fi
            ;;
				     -k14 |--key14)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[14]="$1";
                        shift;
                    fi
            ;;
				     -k15 |--key15)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[15]="$1";
                        shift;
                    fi
            ;;
				     -k16 |--key16)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[16]="$1";
                        shift;
                    fi
            ;;
				     -k17 |--key17)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[17]="$1";
                        shift;
                    fi
            ;;
				     -k18 |--key18)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[18]="$1";
                        shift;
                    fi
            ;;
				     -k19 |--key19)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[19]="$1";
                        shift;
                    fi
            ;;
				     -k20 |--key20)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[20]="$1";
                        shift;
                    fi
            ;;
				     -k21 |--key21)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[21]="$1";
                        shift;
                    fi
            ;;
				     -k22 |--key22)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[22]="$1";
                        shift;
                    fi
            ;;
				     -k23 |--key23)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[23]="$1";
                        shift;
                    fi
            ;;
				     -k24 |--key24)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[24]="$1";
                        shift;
                    fi
            ;;
				     -k25 |--key25)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[25]="$1";
                        shift;
                    fi
            ;;
				     -k26 |--key26)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[26]="$1";
                        shift;
                    fi
            ;;
				     -k27 |--key27)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[27]="$1";
                        shift;
                    fi
            ;;
				     -k28 |--key28)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[28]="$1";
                        shift;
                    fi
            ;;
				     -k29 |--key29)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[29]="$1";
                        shift;
                    fi
            ;;
				     -k30 |--key30)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[30]="$1";
                        shift;
                    fi
            ;;
				     -k31 |--key31)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[31]="$1";
                        shift;
                    fi
            ;;
				     -k32 |--key32)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[32]="$1";
                        shift;
                    fi
            ;;
				     -k33 |--key33)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[33]="$1";
                        shift;
                    fi
            ;;
				     -k34 |--key34)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[34]="$1";
                        shift;
                    fi
            ;;
				     -k35 |--key35)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[35]="$1";
                        shift;
                    fi
            ;;
				     -k36 |--key36)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[36]="$1";
                        shift;
                    fi
            ;;
				     -k37 |--key37)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[37]="$1";
                        shift;
                    fi
            ;;
				     -k38 |--key38)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[38]="$1";
                        shift;
                    fi
            ;;
				     -k39 |--key39)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[39]="$1";
                        shift;
                    fi
            ;;
				     -k40 |--key40)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[40]="$1";
                        shift;
                    fi
            ;;
					-k41 |--key41)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[41]="$1";
                        shift;
                    fi
            ;;
				     -k42 |--key42)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[42]="$1";
                        shift;
                    fi
            ;;
				     -k43 |--key43)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[43]="$1";
                        shift;
                    fi
            ;;
				     -k44 |--key44)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[44]="$1";
                        shift;
                    fi
            ;;
				     -k45 |--key45)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[45]="$1";
                        shift;
                    fi
            ;;
				     -k46 |--key46)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[46]="$1";
                        shift;
                    fi
            ;;
				     -k47 |--key47)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[47]="$1";
                        shift;
                    fi
            ;;
				     -k48 |--key48)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[48]="$1";
                        shift;
                    fi
            ;;
				     -k49 |--key49)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[49]="$1";
                        shift;
                    fi
            ;;
				     -k50 |--key50)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[50]="$1";
                        shift;
                    fi
            ;;
					-k51 |--key51)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[51]="$1";
                        shift;
                    fi
            ;;
				     -k52 |--key52)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[52]="$1";
                        shift;
                    fi
            ;;
				     -k53 |--key53)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[53]="$1";
                        shift;
                    fi
            ;;
				     -k54 |--key54)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[54]="$1";
                        shift;
                    fi
            ;;
				     -k55 |--key55)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[55]="$1";
                        shift;
                    fi
            ;;
				     -k56 |--key56)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[56]="$1";
                        shift;
                    fi
            ;;
				     -k57 |--key57)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[57]="$1";
                        shift;
                    fi
            ;;
				     -k58 |--key58)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[58]="$1";
                        shift;
                    fi
            ;;
				     -k59 |--key59)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[59]="$1";
                        shift;
                    fi
            ;;
				     -k60 |--key60)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[60]="$1";
                        shift;
                    fi
            ;;
				     -k61 |--key61)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[61]="$1";
                        shift;
                    fi
            ;;
				     -k62 |--key62)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[62]="$1";
                        shift;
                    fi
            ;;
				     -k63 |--key63)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[63]="$1";
                        shift;
                    fi
            ;;
				     -k64 |--key64)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[64]="$1";
                        shift;
                    fi
            ;;
				     -k65 |--key65)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[65]="$1";
                        shift;
                    fi
            ;;
				     -k66 |--key66)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[66]="$1";
                        shift;
                    fi
            ;;
				     -k67 |--key67)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[67]="$1";
                        shift;
                    fi
            ;;
				     -k68 |--key68)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[68]="$1";
                        shift;
                    fi
            ;;
				     -k69 |--key69)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[69]="$1";
                        shift;
                    fi
            ;;
				     -k70 |--key70)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[70]="$1";
                        shift;
                    fi
            ;;
					-k71 |--key71)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[71]="$1";
                        shift;
                    fi
            ;;
				     -k72 |--key72)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[72]="$1";
                        shift;
                    fi
            ;;
				     -k73 |--key73)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[73]="$1";
                        shift;
                    fi
            ;;
				     -k74 |--key74)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[74]="$1";
                        shift;
                    fi
            ;;
				     -k75 |--key75)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[75]="$1";
                        shift;
                    fi
            ;;
				     -k76 |--key76)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[76]="$1";
                        shift;
                    fi
            ;;
				     -k77 |--key77)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[77]="$1";
                        shift;
                    fi
            ;;
				     -k78 |--key78)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[78]="$1";
                        shift;
                    fi
            ;;
				     -k79 |--key79)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[79]="$1";
                        shift;
                    fi
            ;;
				     -k80 |--key80)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[80]="$1";
                        shift;
                    fi
            ;;
					-k81 |--key81)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[81]="$1";
                        shift;
                    fi
            ;;
				     -k82 |--key82)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[82]="$1";
                        shift;
                    fi
            ;;
				     -k83 |--key83)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[83]="$1";
                        shift;
                    fi
            ;;
				     -k84 |--key84)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[84]="$1";
                        shift;
                    fi
            ;;
				     -k85 |--key85)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[85]="$1";
                        shift;
                    fi
            ;;
				     -k86 |--key86)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[86]="$1";
                        shift;
                    fi
            ;;
				     -k87 |--key87)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[87]="$1";
                        shift;
                    fi
            ;;
				     -k88 |--key88)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[88]="$1";
                        shift;
                    fi
            ;;
				     -k89 |--key89)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[89]="$1";
                        shift;
                    fi
            ;;
				     -k90 |--key90)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[90]="$1";
                        shift;
                    fi
            ;;
					-k91 |--key91)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[91]="$1";
                        shift;
                    fi
            ;;
				     -k92 |--key92)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[92]="$1";
                        shift;
                    fi
            ;;
				     -k93 |--key93)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[93]="$1";
                        shift;
                    fi
            ;;
				     -k94 |--key94)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[94]="$1";
                        shift;
                    fi
            ;;
				     -k95 |--key95)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[95]="$1";
                        shift;
                    fi
            ;;
				     -k96 |--key96)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[96]="$1";
                        shift;
                    fi
            ;;
				     -k97 |--key97)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[97]="$1";
                        shift;
                    fi
            ;;
				     -k98 |--key98)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[98]="$1";
                        shift;
                    fi
            ;;
				     -k99 |--key99)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[99]="$1";
                        shift;
                    fi
            ;;
				     -k100 |--key100)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[100]="$1";
                        shift;
                    fi
            ;;
				     -k101 |--key101)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[101]="$1";
                        shift;
                    fi
            ;;
				     -k102 |--key102)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[102]="$1";
                        shift;
                    fi
            ;;
				     -k103 |--key103)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[103]="$1";
                        shift;
                    fi
            ;;
				     -k104 |--key104)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[104]="$1";
                        shift;
                    fi
            ;;
				     -k105 |--key105)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[105]="$1";
                        shift;
                    fi
            ;;
				     -k106 |--key106)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[106]="$1";
                        shift;
                    fi
            ;;
				     -k107 |--key107)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[107]="$1";
                        shift;
                    fi
            ;;
				     -k108 |--key108)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[108]="$1";
                        shift;
                    fi
            ;;
				     -k109 |--key109)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[109]="$1";
                        shift;
                    fi
            ;;
				     -k110 |--key110)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[110]="$1";
                        shift;
                    fi
            ;;
				     -k111 |--key111)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[111]="$1";
                        shift;
                    fi
            ;;
				     -k112 |--key112)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[112]="$1";
                        shift;
                    fi
            ;;
				     -k113 |--key113)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[113]="$1";
                        shift;
                    fi
            ;;
				     -k114 |--key114)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[114]="$1";
                        shift;
                    fi
            ;;
				     -k115 |--key115)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[115]="$1";
                        shift;
                    fi
            ;;
				     -k116 |--key116)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[116]="$1";
                        shift;
                    fi
            ;;
				     -k117 |--key117)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[117]="$1";
                        shift;
                    fi
            ;;
				     -k118 |--key118)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[118]="$1";
                        shift;
                    fi
            ;;
				     -k119 |--key119)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[119]="$1";
                        shift;
                    fi
            ;;
				     -k120 |--key120)
            shift;
                    if [ -n "$1" ];
                    then
                        PRIVKEY[120]="$1";
                        shift;
                    fi
            ;;

        --)
            shift;
            break;
            ;;
    esac
done

# Check required arguments
if [ -z "$project" ]
then
    show_help;
fi

# Check required arguments
if [ "$wipe" -eq 1 ]; then
	get_confirmation "Would you really like to WIPE ALL DATA!? YES/NO y/n" && wipe_all
	exit 0
fi

#################################################
# source default config before everything else
source ${SCRIPTPATH}/config/default.env
#################################################

main() {

    echo "starting" &> ${SCRIPT_LOGFILE}
    showbanner

	# debug
	if [ "$debug" -eq 1 ]; then
		echo "********************** VALUES AFTER CONFIG SOURCING: ************************"
		echo "START DEFAULTS => "
		echo "SCRIPT_VERSION:       $SCRIPT_VERSION"
		echo "SSH_INBOUND_PORT:     ${SSH_INBOUND_PORT}"
		echo "SYSTEMD_CONF:         ${SYSTEMD_CONF}"
		echo "NETWORK_CONFIG:       ${NETWORK_CONFIG}"
		echo "NETWORK_TYPE:         ${NETWORK_TYPE}"
		echo "ETH_INTERFACE:        ${ETH_INTERFACE}"
		echo "MNODE_CONF_BASE:      ${MNODE_CONF_BASE}"
		echo "MNODE_DATA_BASE:      ${MNODE_DATA_BASE}"
		echo "MNODE_USER:           ${MNODE_USER}"
		echo "MNODE_HELPER:         ${MNODE_HELPER}"
		echo "MNODE_SWAPSIZE:       ${MNODE_SWAPSIZE}"
		echo "CODE_DIR:             ${CODE_DIR}"
		echo "SCVERSION:            ${SCVERSION}"
		echo "RELEASE:              ${release}"
		echo "SETUP_MNODES_COUNT:   ${SETUP_MNODES_COUNT}"
		echo "END DEFAULTS => "
	fi

	# source project configuration
    source_config ${project}

	# debug
	if [ "$debug" -eq 1 ]; then
		echo "START PROJECT => "
		echo "CODENAME:             $CODENAME"
		echo "SETUP_MNODES_COUNT:   ${SETUP_MNODES_COUNT}"
		echo "MNODE_DAEMON:         ${MNODE_DAEMON}"
		echo "MNODE_INBOUND_PORT:   ${MNODE_INBOUND_PORT}"
		echo "GIT_URL:              ${GIT_URL}"
		echo "SCVERSION:            ${SCVERSION}"
		echo "RELEASE:              ${release}"
		echo "NETWORK_BASE_TAG:     ${NETWORK_BASE_TAG}"
		echo "END PROJECT => "

		echo "START OPTIONS => "
		echo "RELEASE: ${release}"
		echo "PROJECT: ${project}"
		echo "SETUP_MNODES_COUNT: ${count}"
		echo "NETWORK_TYPE: ${NETWORK_TYPE}"
		echo "NETWORK_TYPE: ${net}"

		echo "END OPTIONS => "
		echo "********************** VALUES AFTER CONFIG SOURCING: ************************"
	fi
}

main "$@"
