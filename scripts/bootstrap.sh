
VERSION=1.4.1
# if ca version not passed in, default to latest released version
CA_VERSION=1.4.1
# current version of thirdparty images (couchdb, kafka and zookeeper) released
THIRDPARTY_IMAGE_VERSION=0.4.15
ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')")


dockerFabricPull() {
  local FABRIC_TAG=$1
  for IMAGES in peer orderer ccenv tools nodeenv javaenv; do
      echo "==> FABRIC IMAGE: $IMAGES"
      echo
      docker pull "hyperledger/fabric-$IMAGES:$FABRIC_TAG"
      docker tag "hyperledger/fabric-$IMAGES:$FABRIC_TAG" "hyperledger/fabric-$IMAGES"
  done
}

dockerThirdPartyImagesPull() {
  local THIRDPARTY_TAG=$1
  for IMAGES in couchdb kafka zookeeper baseos; do
      echo "==> THIRDPARTY DOCKER IMAGE: $IMAGES"
      echo
      docker pull "hyperledger/fabric-$IMAGES:$THIRDPARTY_TAG"
      docker tag "hyperledger/fabric-$IMAGES:$THIRDPARTY_TAG" "hyperledger/fabric-$IMAGES"
  done
}

dockerCaPull() {
      local CA_TAG=$1
      echo "==> FABRIC CA IMAGE"
      echo
      docker pull "hyperledger/fabric-ca:$CA_TAG"
      docker tag "hyperledger/fabric-ca:$CA_TAG" hyperledger/fabric-ca
}

binaryIncrementalDownload() {
      local BINARY_FILE=$1
      local URL=$2
      curl -f -s -C --insecure - "${URL}" -o "${BINARY_FILE}" || rc=$?
      # Due to limitations in the current Nexus repo:
      # curl returns 33 when there's a resume attempt with no more bytes to download
      # curl returns 2 after finishing a resumed download
      # with -f curl returns 22 on a 404
      if [ "$rc" = 22 ]; then
	  # looks like the requested file doesn't actually exist so stop here
	  return 22
      fi
      if [ -z "$rc" ] || [ $rc -eq 33 ] || [ $rc -eq 2 ]; then
          # The checksum validates that RC 33 or 2 are not real failures
          echo "==> File downloaded. Verifying the md5sum..."
          localMd5sum=$(md5sum "${BINARY_FILE}" | awk '{print $1}')
          remoteMd5sum=$(curl -s "${URL}".md5)
          if [ "$localMd5sum" == "$remoteMd5sum" ]; then
              echo "==> Extracting ${BINARY_FILE}..."
              tar xzf ./"${BINARY_FILE}" --overwrite
	      echo "==> Done."
              rm -f "${BINARY_FILE}" "${BINARY_FILE}".md5
          else
              echo "Download failed: the local md5sum is different from the remote md5sum. Please try again."
              rm -f "${BINARY_FILE}" "${BINARY_FILE}".md5
              exit 1
          fi
      else
          echo "Failure downloading binaries (curl RC=$rc). Please try again and the download will resume from where it stopped."
          exit 1
      fi
}


binaryDownload() {
      local BINARY_FILE=$1
      local URL=$2
      echo "===> Downloading: " "${URL}"
      # Check if a previous failure occurred and the file was partially downloaded
      if [ -e "${BINARY_FILE}" ]; then
          echo "==> Partial binary file found. Resuming download..."
          binaryIncrementalDownload "${BINARY_FILE}" "${URL}"
      else
          curl --insecure "${URL}" | tar xz || rc=$?
          if [ -n "$rc" ]; then
              echo "==> There was an error downloading the binary file. Switching to incremental download."
              echo "==> Downloading file..."
              binaryIncrementalDownload "${BINARY_FILE}" "${URL}"
	  else
	      echo "==> Done."
          fi
      fi
}

binariesInstall() {
  echo "===> Downloading version ${FABRIC_TAG} platform specific fabric binaries"
  binaryDownload "${BINARY_FILE}" "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/${ARCH}-${VERSION}/${BINARY_FILE}"
  if [ $? -eq 22 ]; then
     echo
     echo "------> ${FABRIC_TAG} platform specific fabric binary is not available to download <----"
     echo
   fi

  echo "===> Downloading version ${CA_TAG} platform specific fabric-ca-client binary"
  binaryDownload "${CA_BINARY_FILE}" "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric-ca/hyperledger-fabric-ca/${ARCH}-${CA_VERSION}/${CA_BINARY_FILE}"
  if [ $? -eq 22 ]; then
     echo
     echo "------> ${CA_TAG} fabric-ca-client binary is not available to download  (Available from 1.1.0-rc1) <----"
     echo
   fi
}

dockerInstall() {
  command -v docker >& /dev/null
  NODOCKER=$?
  if [ "${NODOCKER}" == 0 ]; then
	  echo "===> Pulling fabric Images"
	  dockerFabricPull "${FABRIC_TAG}"
	  echo "===> Pulling fabric ca Image"
	  dockerCaPull "${CA_TAG}"
	  echo "===> Pulling thirdparty docker images"
	  dockerThirdPartyImagesPull "${THIRDPARTY_TAG}"
	  echo
	  echo "===> List out hyperledger docker images"
	  docker images | grep hyperledger
  else
    echo "========================================================="
    echo "Docker not installed, bypassing download of Fabric images"
    echo "========================================================="
  fi
}

export FABRIC_TAG=${VERSION}
export CA_TAG=${CA_VERSION}
export THIRDPARTY_TAG=${THIRDPARTY_IMAGE_VERSION}

BINARY_FILE=hyperledger-fabric-${ARCH}-${VERSION}.tar.gz
CA_BINARY_FILE=hyperledger-fabric-ca-${ARCH}-${CA_VERSION}.tar.gz

binariesInstall

dockerInstall