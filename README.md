This is a template project for the walkthrough of the code that we will be writing.

Step I: 

Download the binaries required by Hyperledger Fabric

Run .\scripts\bootstrap.sh in the default folder which will allow you to download the binaries in the bin folder and also create a config folder

Step II: 

The very first thing that is important for the functioning of the network as a whole is the creation of the the certificates that would be used by hyperledger nodes (peers and orderers) to validate each other's identities by signing the transactions that happen over the network.

For that we will go ahead and create a file called crypto-config.yaml that allows us to create these certificates that the different entities on the blockchain network would use.

The crypto conifg.yaml file is composed of two sections.

OrdererOrgs and PeerOrgs

OrdererOrgs:

This is a specification for the cetrtificates that will be generated for the 

once you are done with the crypto-config.yaml file, just go ahead and generate the crypto materials using:

./bin/cryptogen generate --config=./crypto-config.yaml

if you want to add crypto materials for a new org without doing away with the old ones use the extend command

Step III:

Creating the artefacts for a channel to be started using the configtxgen tool.

The main environemnt variable that is defined for the file is FABRIC_CFG_PATH, if it isn't there then the tool searches the current folder for configtx.yaml

creating the orderer block

./bin/configtxgen -configPath ./config -outputBlock ./channel-artifacts/genesis.block -profile SuperheroGenesis -channelID shorderer 

creating the channel transactions

./bin/configtxgen -outputCreateChannelTx ./channel-artifacts/shchannel.tx -profile SHChannel -configPath ./config -channelID shchannel

creating the anchor peers update

./bin/configtxgen -outputAnchorPeersUpdate ./channel-artifacts/hydanchor.tx -profile SHChannel -asOrg hydratings -configPath ./config  -channelID shchannel

./bin/configtxgen -outputAnchorPeersUpdate ./channel-artifacts/ggnanchor.tx -profile SHChannel -asOrg ggnratings -configPath ./config  -channelID shchannel

Step IV: Orderer.Yaml file

Step V: Core.yaml file

Bootstrap will download a core.yaml file in the config directory. That file contains all the defaults for a peer.

events are isolated on channels.

Filtered Mode: Block info summary and Transaction status

less restrictive


Un Filtered: All of transaction information

more restrictive.

ChainCode:

for debugging launch a peer in chaincodedevmode









