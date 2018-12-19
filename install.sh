DISTRO=$(cat /etc/*-release | grep -w NAME | cut -d= -f2 | tr -d '"')
SOURCE_DIR=$(pwd)/collectd
INSTALL_DIR=''
DISTRO_PKG_MAN=''
MACHINE_NAME=$1
TMP_PATH=$(mktemp -d)

if [ -z $2 ]; then
	GRAPHITE_IP='10.60.0.27'
else
	GRAPHITE_IP=$2
fi

trap "{ rm -rf $TMP_PATH; }" EXIT

function getting_distro_info {
	if [[ "$DISTRO" == *"Ubuntu"* ]]; then
		INSTALL_DIR='/etc/collectd'
		DISTRO_PKG_MAN='apt-get'
	elif [[ "$DISTRO" == *"CentOS"* ]]; then
		INSTALL_DIR='/etc/collectd.d'
		DISTRO_PKG_MAN='yum'
	elif [[ "$DISTRO" == *"Oracle"* ]]; then
		INSTALL_DIR='/etc/collectd.d'
		DISTRO_PKG_MAN='yum'
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
	eval "sudo $DISTRO_PKG_MAN -q update"
}

function dependencies_install {
	echo "---> Installing necessaries dependencies"
	echo "-----> Collectd and Dependencies"
	eval "sudo $DISTRO_PKG_MAN -q install collectd collectd-utils collectd-core collectd-ping liboping0"
}

function configuring_collectd {
	echo "-----> Configuring Collectd"
	eval "cp ${PWD}/collectd/collectd.tmpl ${TMP_PATH}/collectd.conf"
	sed -i -e "s@{MACHINE_NAME}@${MACHINE_NAME}@" -e "s@{INSTALL_DIR}@${INSTALL_DIR}@" -e "s@{GRAPHITE_IP}@${GRAPHITE_IP}@" ${TMP_PATH}/collectd.conf 
	eval "sudo cp --force ${TMP_PATH}/collectd.conf ${INSTALL_DIR}/"
	echo "-----> Creating log path for Collectd in /var/log/collectd"
	eval "sudo mkdir -p /var/log/collectd"
	echo "-----> Starting Collectd"
	eval "sudo collectd -C ${INSTALL_DIR}/collectd.conf"
}

getting_distro_info
starting_text
updating_packages
dependencies_install
configuring_collectd
exit 0

