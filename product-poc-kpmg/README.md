# Attribute based access control

In the POC - `product-poc-kpmg` Attribute-based access control has been used. It uses authorization based on individual client identities to allow the users that interact with the network to own products on the blockchain ledger.


Following are the functionalities of smart contract implemented.

To add new products (allowed only to admin of Org)
To view all products (allowed to specific users by admins of Org)
Remove a product (allowed to specific users by admins of Org)
Remove all products (allowed only to admin of org)

The `product-poc-kpmg` smart contract allows you to create products that can be updated or transferred by the product owner. The ability to create or remove products from the ledger is restricted to identities with the `kpmg.admin=true` attribute. 

## Start the network and deploy the smart contract

We can use the Fabric test network to deploy and interact with the `product-poc-kpmg` smart contract. Run the following command to change into the test network directory and bring down any running nodes:

cd fabric-samples/test-network

./testScript startNetwork   
./testScript exportConfig

## Login user - This will update the user access in the chaincode

./testScript adminLogin

./testScript userLogin

## Create an product - Create 2 admin users and a general user

./testScript createUser 

## View the product

./testScript viewProduct -p PRODUCTID

## Update the product

./testScript updateProduct -p PRODUCTID

## Delete the product

./testScript deleteProduct -p PRODUCTID

## Clean up

When you are finished, you can run the following command to bring down the test network:
```
./network.sh down
```
