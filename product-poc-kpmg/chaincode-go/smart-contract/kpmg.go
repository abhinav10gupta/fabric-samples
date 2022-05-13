package kpmg

import (
	"encoding/base64"
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing an Product
type SmartContract struct {
	contractapi.Contract
}

// Product describes basic details of what makes up a simple product
type Product struct {
	ID             string `json:"ID"`
	Brand          string `json:"brand"`
	ModelNo        int    `json:"modelNo"`
	Owner          string `json:"owner"`
	Price		   int    `json:"price"`
}

// AddProduct issues a new product to the world state with given details.
func (s *SmartContract) AddProduct(ctx contractapi.TransactionContextInterface, id string, brand string, modelNo int, price int) error {

	//
	err := ctx.GetClientIdentity().AssertAttributeValue("kpmg.admin", "true")
	if err != nil {
		return fmt.Errorf("submitting client not authorized to add product, does not have kpmg.admin role")
	}

	exists, err := s.ProductExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("the product %s already exists", id)
	}

	// Get ID of submitting client identity
	clientID, err := s.GetSubmittingCIdentity(ctx)
	if err != nil {
		return err
	}

	product := Product{
		ID:             id,
		Brand:          brand,
		ModelNo:        modelNo,
		Owner:          clientID,
		Price:			price,
	}
	productJSON, err := json.Marshal(product)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, productJSON)
}

// UpdateProduct updates an existing product in the world state with provided parameters.
func (s *SmartContract) UpdateProduct(ctx contractapi.TransactionContextInterface, id string, newBrand string, newModelNo int, newValue int) error {

	product, err := s.ReadProduct(ctx, id)
	if err != nil {
		return err
	}

	clientID, err := s.GetSubmittingCIdentity(ctx)
	if err != nil {
		return err
	}

	if clientID != product.Owner {
		return fmt.Errorf("submitting client not authorized to update product, does not own product")
	}

	product.Brand = newBrand
	product.ModelNo = newModelNo
	product.Price = newValue

	productJSON, err := json.Marshal(product)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, productJSON)
}

// DeleteProduct deletes a given product from the world state.
func (s *SmartContract) DeleteProduct(ctx contractapi.TransactionContextInterface, id string) error {

	product, err := s.ReadProduct(ctx, id)
	if err != nil {
		return err
	}

	clientID, err := s.GetSubmittingCIdentity(ctx)
	if err != nil {
		return err
	}

	if clientID != product.Owner {
		return fmt.Errorf("submitting client not authorized to update product, does not own product")
	}

	return ctx.GetStub().DelState(id)
}

// Transfer product ownership, the owner field of product with given id in world state.
func (s *SmartContract) TransferProductOwnership(ctx contractapi.TransactionContextInterface, id string, newOwner string) error {

	product, err := s.ReadProduct(ctx, id)
	if err != nil {
		return err
	}

	clientID, err := s.GetSubmittingCIdentity(ctx)
	if err != nil {
		return err
	}

	if clientID != product.Owner {
		return fmt.Errorf("submitting client not authorized to update product, does not own product")
	}

	product.Owner = newOwner
	productJSON, err := json.Marshal(product)
	if err != nil {
		return err
	}
 
	return ctx.GetStub().PutState(id, productJSON)
}

// ReadProduct returns the product stored in the world state with given id.
func (s *SmartContract) ReadProduct(ctx contractapi.TransactionContextInterface, id string) (*Product, error) {

	productJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if productJSON == nil {
		return nil, fmt.Errorf("the product %s does not exist", id)
	}

	var product Product
	err = json.Unmarshal(productJSON, &product)
	if err != nil {
		return nil, err
	}

	return &product, nil
}

// GetAllProducts returns all products found in world state
func (s *SmartContract) GetAllProducts(ctx contractapi.TransactionContextInterface) ([]*Product, error) {

	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var products []*Product
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var product Product
		err = json.Unmarshal(queryResponse.Value, &product)
		if err != nil {
			return nil, err
		}
		products = append(products, &product)
	}

	return products, nil
}

// ProductExists returns true when product with given ID exists in world state
func (s *SmartContract) ProductExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {

	productJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return productJSON != nil, nil
}

// GetSubmittingCIdentity returns the name and issuer of the identity that
// invokes the smart contract. This function base64 decodes the identity string
// before returning the value to the client or smart contract.

func (s *SmartContract) GetSubmittingCIdentity(ctx contractapi.TransactionContextInterface) (string, error) {

	bID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return "", fmt.Errorf("Failed to read clientID: %v", err)
	}
	decodeID, err := base64.StdEncoding.DecodeString(bID)
	if err != nil {
		return "", fmt.Errorf("failed to base64 decode clientID: %v", err)
	}
	return string(decodeID), nil
}
