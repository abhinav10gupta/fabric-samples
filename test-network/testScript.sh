
# It would clean all the previous docker containers and images, then initiate a new network
# creation and deploys the chaincode 

function startNetwork() {
    ./network.sh down
    ./network.sh up createChannel -ca
    ./network.sh deployCC -ccn kpmg -ccp ../product-poc-kpmg/chaincode-go/ -ccl go
}


function exportConfig() {
    
    export PATH=${PWD}/../bin:${PWD}:$PATH
    export FABRIC_CFG_PATH=$PWD/../config/
    
    export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org1.example.com/
    export CORE_PEER_TLS_ENABLED=true
    
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
    
    export CORE_PEER_ADDRESS=localhost:7051
    export TARGET_TLS_OPTIONS="-o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
}

function createUser(){

# Add 1st admin user - admin1 
fabric-ca-client register --id.name admin1 --id.secret admin1pw --id.type client --id.affiliation org1 --id.attrs 'kpmg.admin=true:ecert' --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem

fabric-ca-client enroll -u https://admin1:admin1pw@localhost:7054 --caname ca-org1 -M ${PWD}/organizations/peerOrganizations/org1.example.com/users/admin1@org1.example.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem

cp ${PWD}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org1.example.com/users/admin1@org1.example.com/msp/config.yaml


# Add 2nd admin user - admin2
fabric-ca-client register --id.name admin2 --id.secret admin1pw --id.type client --id.affiliation org1 --id.attrs 'kpmg.admin=true:ecert' --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem

fabric-ca-client enroll -u https://admin2:admin1pw@localhost:7054 --caname ca-org1 -M ${PWD}/organizations/peerOrganizations/org1.example.com/users/admin2@org1.example.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem

cp ${PWD}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org1.example.com/users/admin2@org1.example.com/msp/config.yaml



# Add 1st General user - user1 
fabric-ca-client register --id.name user1 --id.secret user1 --id.type client --id.affiliation org1 --id.attrs 'kpmg.admin=false:ecert' --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem

fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-org1 -M ${PWD}/organizations/peerOrganizations/org1.example.com/users/user1@org1.example.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem

cp ${PWD}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org1.example.com/users/user1@org1.example.com/msp/config.yaml

} 


## Login configurations for admin1 user
function adminLogin(){
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/admin1@org1.example.com/msp
    echo 'User ID' ${USER} 'Logged In'
}

## Login configurations for user1
function userLogin(){
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/user1@org1.example.com/msp
    echo 'User ID' ${USER} 'Logged In'
}

## Add product details, Product ID is uniques other data is hardcoded as of now for testing purpose
function addProduct(){
    peer chaincode invoke $TARGET_TLS_OPTIONS -C mychannel -n kpmg -c '{"function":"AddProduct","Args":["'${PRODUCT}'" ,"Apple","9999","100000"]}'
}


## Update product details, Product ID is uniques other data is hardcoded as of now for testing purpose
function updateProduct(){
    peer chaincode invoke $TARGET_TLS_OPTIONS -C mychannel -n kpmg -c '{"function":"UpdateProduct","Args":["'${PRODUCT}'" ,"SAMSUNG","11111","66666"]}'
}

## View functionality is applicable for all the users 
function viewProduct(){
    peer chaincode query -C mychannel -n kpmg -c '{"function":"ReadProduct","Args":["'${PRODUCT}'"]}'
}


## Only authorised user can delete the records of the product
function deleteProduct(){
    peer chaincode invoke $TARGET_TLS_OPTIONS -C mychannel -n kpmg -c '{"function":"DeleteProduct","Args":["'${PRODUCT}'"]}'
}


## We can change the ownership of the product and only the owner can perform update and delete opeartion
function updateOwner(){
    export RECIPIENT="x509::CN='"${USER}"',OU=client,O=Hyperledger,ST=Karnataka,C=INDIA::CN=ca.org1.example.com,O=org1.example.com,L=WhiteField,ST=Karnataka,C=INDIA"

    peer chaincode invoke $TARGET_TLS_OPTIONS -C mychannel -n kpmg -c '{"function":"TransferProductOwnership","Args":["Product1","'"$RECIPIENT"'"]}'

}

## Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp
    exit 0
    ;;
  -u )
    USER="$2"
    shift
    ;;
  -p )
    PRODUCT="$2"
    shift
    ;;
  * )
    errorln "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done



if [ "${MODE}" == "startNetwork" ]; then
  startNetwork
elif [ "${MODE}" == "exportConfig" ]; then
  exportConfig
elif [ "${MODE}" == "createUser" ]; then
  createUser
elif [ "${MODE}" == "adminLogin" ]; then
  adminLogin
elif [ "${MODE}" == "userLogin" ]; then
  userLogin
elif [ "${MODE}" == "addProducts" ]; then
  addProducts
elif [ "${MODE}" == "updateProduct" ]; then
  updateProduct
elif [ "${MODE}" == "viewProduct" ]; then
  viewProduct
elif [ "${MODE}" == "deleteProduct" ]; then
  deleteProduct
elif [ "${MODE}" == "updateOwner" ]; then
  updateOwner
else
  printHelp
  exit 1
fi