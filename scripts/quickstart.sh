#!/bin/bash
set -e

##################### Variables Section Start #####################

if [[ "${TERM/term}" = "$TERM" ]]; then
  COLUMNS=50
else
  COLUMNS=$(tput cols)
fi
CURRENT_DIR="`pwd`"
MACHINE_HOME=$CURRENT_DIR/predix-scripts/bash/PredixMachine
GLOBAL_APPENDER=""
GIT_BRANCH="master"
COMPILE_REPO=0
use_backup_uaa=0

export COLUMNS
##################### Variables Section End   #####################
__echo_run() {
  echo $@
  $@
  return $?
}

__print_center() {
  len=${#1}
  sep=$2
  buf=$((($COLUMNS-$len-2)/2))
  line=""
  for (( i=0; i < $buf; i++ )) {
    line="$line$sep"
  }
  line="$line $1 "
  for (( i=0; i < $buf; i++ )) {
    line="$line$sep"
  }
  echo ""
  echo $line
}

arguments="$*"
echo "Arguments $arguments"
echo "$CURRENT_DIR"
rm -rf predix-scripts
rm -rf predix-machine-templates


__echo_run git clone https://github.com/PredixDev/predix-scripts.git  

__print_center "Creating Cloud Services" "#"
cd predix-scripts/bash

source readargs.sh

if type dos2unix >/dev/null; then
	find . -name "*.sh" -exec dos2unix -q {} \;
fi

#Run the quickstart
__echo_run ./quickstart.sh -cs -mc -if $arguments
cd $CURRENT_DIR

__print_center "Build and setup the Predix Machine Adapter for Sample Data generator" "#"

__echo_run cp $CURRENT_DIR/config/com.ge.predix.solsvc.workshop.adapter.config $MACHINE_HOME/configuration/machine
__echo_run cp $CURRENT_DIR/config/com.ge.predix.workshop.nodeconfig.json $MACHINE_HOME/configuration/machine
__echo_run cp $CURRENT_DIR/config/com.ge.dspmicro.hoover.spillway-0.config $MACHINE_HOME/configuration/machine

if [[ $RUN_COMPILE_REPO == 1 ]]; then
	mvn -q clean install -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8 -f $CURRENT_DIR/pom.xml
fi
__echo_run cp $CURRENT_DIR/config/solution.ini $MACHINE_HOME/machine/bin/vms
__echo_run cp $CURRENT_DIR/config/start_container.sh $MACHINE_HOME/machine/bin/predix
__echo_run cp $CURRENT_DIR/target/predix-machine-template-adapter-simulator-1.0.jar $MACHINE_HOME/machine/bundles

__print_center "Predix Machine is now available at $MACHINE_HOME" "#"

PREDIX_SERVICES_SUMMARY_FILE="$CURRENT_DIR/predix-scripts/bash/log/predix-services-summary.txt"

echo "" >> $PREDIX_SERVICES_SUMMARY_FILE
echo "Edge Device Specific Configuration" >> $PREDIX_SERVICES_SUMMARY_FILE
echo "What did we do:"  >> $PREDIX_SERVICES_SUMMARY_FILE
echo "We setup some configuration files in the Predix Machine container to read from a DataNode for our sensors"  >> $PREDIX_SERVICES_SUMMARY_FILE
echo "We built and deployed the Machine Adapter bundle which generates sample data" >> $PREDIX_SERVICES_SUMMARY_FILE
echo "" >> $PREDIX_SERVICES_SUMMARY_FILE
echo "You can now start Machine as follows" >> $PREDIX_SERVICES_SUMMARY_FILE
echo "cd $MACHINE_HOME/machine/bin/predix" >> $PREDIX_SERVICES_SUMMARY_FILE
echo "./start_container.sh clean" >> $PREDIX_SERVICES_SUMMARY_FILE
echo "" >> $PREDIX_SERVICES_SUMMARY_FILE
