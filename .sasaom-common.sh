exitWithError() {
  echo "*ERROR* > $1"
  exit 1
}

[[ -z $VIYAENV ]] && exitWithError "*ERROR* The env variable VIYAENV must be defined (e.g.: export VIYAENV=VIYA4DEV)"
[[ -z $BASEDIR ]] && exitWithError "*ERROR* The env variable BASEDIR must be defined (e.g.: export BASEDIR=/prj)"