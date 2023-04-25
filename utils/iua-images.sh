#!/bin/bash
set -e

GRN='\e[32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

VERSION="2.6.0"
DOWNLOAD_LINK="https://info.gosuslugi.ru/download.php?id=1807"
GOV_REPO="registry.00.egov.local/iua-prod"
DOCKER_REPO="dockerhub.smk-systems.ru:5000/iua-smev3"


##
# Download images
##
download() {

  if [ ! -z "${1}" ]; then
    VERSION="${1}"
  else
    read -r -p "Confirm adapter version [${VERSION}]: " ans ; [ -z "${ans}" ] && ans="${VERSION}" || VERSION="${ans}"
  fi

  if [ ! -d "iua-images-${VERSION}" ]; then
    tarball="iua-${VERSION}.tar.gz"
    if [ ! -f "${tarball}" ]; then
      read -r -p "Check download link [${DOWNLOAD_LINK}]: " ans ; [ -z "${ans}" ] && ans=${DOWNLOAD_LINK} || DOWNLOAD_LINK=${ans}
      wget --content-disposition "${DOWNLOAD_LINK}"
    fi

    tar -xfz "${tarball}"
    rc=$?
    if [ $rc -ne 0 ]; then
        echo -e "${RED}Aborted. Could not perform 'tar xf ${tarball}', exit code [$rc].${NC}"; exit $rc
    fi

    mv "iua-images" "iua-images-${VERSION}"
  fi
}

##
# Import docker images to local repository:
##
load() {
  if [ ! -z "${1}" ]; then
    dir="${1}"
  else
    dir="iua-images"
    read -r -p "Please select a folder [${dir}]: " ans ; [ -z "${ans}" ] && ans="${dir}" || dir="${ans}"
  fi
  if [ ! -d "${dir}" ]; then 
    echo -e "${RED}No such file or directory: ${dir}${NC}"
    exit 1
  fi

  if [ ! -z "${2}" ]; then
    VERSION="${2}"
  else
    read -r -p "Confirm adapter version [${VERSION}]: " ans ; [ -z "${ans}" ] && ans="${VERSION}" || VERSION="${ans}"
  fi

  cnt=$(find "${dir}" -type f -name "*.tar"| wc -l)
  if [ "${cnt}" -eq 0 ]; then 
    echo -e "${RED}No files to load to registry${NC}"
    echo "Try run: ${0} --download"
    exit 0
  fi
    
  #docker images "${GOV_REPO}/*:${VERSION}"

  if [ `docker images "${GOV_REPO}/*:${VERSION}" | wc -l` -eq "${cnt}" ]
  then
    echo -e "${GRN}Images successfully loaded.${NC}"
  else
    for t in "${dir}/*.tar"; do 
      docker load -i ${t};
    done
    echo -e "${GRN}Images successfully loaded.${NC}"
  fi 
}


## 
# Push images to private repository:
##
push() {
  if [ ! -z "${1}" ]; then
    DOCKER_REPO="${1}"
  else
    read -r -p "Enter docker registry address [${DOCKER_REPO}]: " ans ; [ -z "${ans}" ] && ans=${DOCKER_REPO} || DOCKER_REPO=${ans}
  fi
  
  echo "docker login ${DOCKER_REPO}" 
  docker login ${DOCKER_REPO}

  docker images | grep --color "${GOV_REPO}" | while read line; do 
    full=$(echo $line | awk '{print $1}')
    name=$(cut -d '/' -f3 <<< ${full})
    tag=$(echo $line | awk '{print $2}')
    id=$(echo $line | awk '{print $3}')

    echo "------- ${DOCKER_REPO}/${name}:${tag}"
    docker tag ${id} ${DOCKER_REPO}/${name}:${tag}
    docker push ${DOCKER_REPO}/${name}:${tag}
  done
}


while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--load)
      load $2 $3
      exit 0
      ;;

    -d|--download)
      download $2
      exit 0
      ;;

    -p|--push)
      push $2
      exit 0
      ;;

    -*|--*)
      echo "Unknown option $1"
      exit 1
  esac
done
