DISTRO=$(cat /etc/*-release | grep -w NAME | cut -d= -f2 | tr -d '"')
SOURCE_DIR=$(pwd)/collectd
INSTALL_DIR=''
COLLECTD_DIR=''
DISTRO_PKG_MAN=''
MACHINE_NAME=$1

TMP_PATH=$(mktemp -d)
if [ $? -ne 0 ]; then
   	show_error "while creating temporary path."
fi

if [ -z $2 ]; then
	GRAPHITE_IP='10.60.0.27'
else
	GRAPHITE_IP=$2
fi

trap "{ rm -rf $TMP_PATH; }" EXIT

function show_error {
	echo ""
	echo ""
	echo "A error happened while $1"
	echo "Aborting!"
	exit 1 ;
}

function getting_distro_info {
	if [[ "$DISTRO" == *"Ubuntu"* ]]; then
		INSTALL_DIR='/etc/collectd'
		COLLECTD_DIR='/etc/collectd/collectd.conf.d'
		DISTRO_PKG_MAN='apt-get -m -y'
	elif [[ "$DISTRO" == *"CentOS"* ]] || [[ "$DISTRO" == *"Oracle"* ]]; then
		INSTALL_DIR='/etc'
		COLLECTD_DIR='/etc/collectd.d'
		DISTRO_PKG_MAN='yum -q -y'
	else 
		echo "No OS detected"
		echo "Aborting..."
		exit 1 ;
	fi
}

function starting_text {
	clear
	echo "**************************************"
	echo "* Starting DAPP FGV Collectd Install *"
	echo "**************************************"
	echo ""
	echo "-> $DISTRO Detected"
	echo "---> Preparing to install in this distribution"
}

function updating_packages {
	echo "---> Updating package lists"
	eval "sudo $DISTRO_PKG_MAN update"
	if [ $? -ne 0 ]; then
    	show_error "updating package list."
	fi
}

function dependencies_install {
	echo "---> Installing necessary dependencies"
	echo "-----> Collectd and Dependencies"
	eval "sudo $DISTRO_PKG_MAN install collectd collectd-utils collectd-core"
	if [ $? -ne 0 ]; then
    	show_error "installing necessary dependencies."
	fi
	echo "-----> Collectd plugins"
	eval "sudo $DISTRO_PKG_MAN install collectd-ping liboping0 collectd-nginx"
	if [ $? -ne 0 ]; then
    	echo "-----> Could not install collectd plugins. Moving forward. <-----"
	fi
}

function configuring_collectd {
	echo "-----> Configuring Collectd"

	eval "cp ${PWD}/collectd/collectd.tmpl ${TMP_PATH}/collectd.conf"
	if [ $? -ne 0 ]; then
    	show_error "moving contents to temporary path."
	fi

	sed -i -e "s@{MACHINE_NAME}@${MACHINE_NAME}@" -e "s@{COLLECTD_DIR}@${COLLECTD_DIR}@" -e "s@{GRAPHITE_IP}@${GRAPHITE_IP}@" ${TMP_PATH}/collectd.conf 
	if [ $? -ne 0 ]; then
    	show_error "creating collectd config file."
	fi

	eval "sudo cp --force ${TMP_PATH}/collectd.conf ${INSTALL_DIR}/"
	if [ $? -ne 0 ]; then
    	show_error "copying collectd configuration file."
	fi
	
	echo "-----> Creating log path for Collectd in /var/log/collectd"
	eval "sudo mkdir -p /var/log/collectd"
	if [ $? -ne 0 ]; then
    	show_error "creating log path for collectd."
	fi

	echo "-----> Starting Collectd"
	eval "sudo collectd -C ${INSTALL_DIR}/collectd.conf"
	if [ $? -ne 0 ]; then
    	show_error "starting collectd."
	fi
}

getting_distro_info
starting_text
updating_packages
dependencies_install
configuring_collectd
exit 0

