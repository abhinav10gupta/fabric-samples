/*
SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"log"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	kpmg "github.com/hyperledger/fabric-samples/product-poc-kpmg/chaincode-go/smart-contract"
)

func main() {
	kpmgSmartContract, err := contractapi.NewChaincode(&kpmg.SmartContract{})
	if err != nil {
		log.Panicf("Error creating kpmg chaincode: %v", err)
	}

	if err := kpmgSmartContract.Start(); err != nil {
		log.Panicf("Error starting kpmg chaincode: %v", err)
	}
}
