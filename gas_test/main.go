package main

import (
	"context"
	"crypto/ed25519"
	"encoding/hex"
	"fmt"
	"strconv"
	"time"

	"github.com/portto/aptos-go-sdk/client"
	"github.com/portto/aptos-go-sdk/models"
)

const ChainID = 2
const Decimal = 100000000
const CollectionName = "Aptos"
const TokenName = "Aptos Token"
const GasPrice = uint64(100)
const DefaultMaxGasAmount = uint64(5000)

// const OwnerAddr = "572941edfecf00c392ebf17fdb20729be425ecb5ce018999f19e7e2be534676f"
// const UserAddr = "c0cc333a8a8b22a716afc439fbf52b2b8c2fabdabb9c425daf7937945749be6b"
// const UserSeed = "6bbee9dce763f60c672f10a48a024d6e6d3306240095fe00e80afc972196b973"
const OwnerAddr = "880f255dea4800fcea4b640cc6a9dfdb711f6d75a89719d7e06f936d3b8dbaea"
const UserAddr = "edee10d387fcc2f10d54d12dd69ce973dd8b4f0e7a59f0fbb57db64500d7ce5c"
const UserSeed = "c677c67d15e8c3117f0f96f577bd976968a44ae25868fb9ff0756d1bfd132072"

var aptosClient client.AptosClient
var tokenClient client.TokenClient

var addr0x1 models.AccountAddress
var aptosCoinTypeTag models.TypeTag

var owner models.AccountAddress
var user models.AccountAddress

var Urn2EarnModule models.Module

var ctx = context.Background()

func init() {
	var err error

	networkURL := "https://fullnode.testnet.aptoslabs.com"
	// networkURL := "http://0.0.0.0:8080"
	aptosClient = client.NewAptosClient(networkURL)
	tokenClient, err = client.NewTokenClient(aptosClient, "https://indexer-testnet.staging.gcp.aptosdev.com/v1/graphql")
	if err != nil {
		panic(err)
	}

	addr0x1, _ = models.HexToAccountAddress("0x1")

	aptosCoinTypeTag = models.TypeTagStruct{
		Address: addr0x1,
		Module:  "aptos_coin",
		Name:    "AptosCoin",
	}

	owner, err = models.HexToAccountAddress(OwnerAddr)
	if err != nil {
		panic(fmt.Errorf("models.HexToAccountAddress error: %v", err))
	}

	Urn2EarnModule = models.Module{
		Address: owner,
		Name:    "urn_to_earn",
	}

	user, err = models.HexToAccountAddress(UserAddr)
	if err != nil {
		panic(fmt.Errorf("models.HexToAccountAddress error: %v", err))
	}
}

func main() {
	printBalance()
	ob := getBalance(owner)
	ub := getBalance(user)

	txResp, err := mintShovel(aptosClient, user)
	if err != nil {
		panic(fmt.Errorf("mint shovel error: %v", err))
	}
	aptosClient.WaitForTransaction(ctx, txResp.Hash)

	printBalance()
	fmt.Printf("owner balance diff %f\n", getBalance(owner)-ob)
	fmt.Printf("user balance diff %f\n", getBalance(user)-ub)
}

func getBalance(aa models.AccountAddress) float64 {
	coinRes, err := aptosClient.GetResourceByAccountAddressAndResourceType(
		ctx,
		aa.ToHex(),
		fmt.Sprintf("0x1::coin::CoinStore<%s>", "0x1::aptos_coin::AptosCoin"),
	)
	if err != nil {
		panic(fmt.Errorf("get balance error: %v", err))
	}

	v, err := strconv.ParseFloat(coinRes.Data.Coin.Value, 64)
	if err != nil {
		panic(fmt.Errorf("parse balance error: %v", err))
	}

	return v
}

func printBalance() {
	ownerBalance, err := aptosClient.GetResourceByAccountAddressAndResourceType(
		ctx,
		owner.ToHex(),
		fmt.Sprintf("0x1::coin::CoinStore<%s>", "0x1::aptos_coin::AptosCoin"),
	)
	if err != nil {
		panic(fmt.Errorf("get owner balance error: %v", err))
	}

	printCoinRes(ownerBalance)

	userBalance, err := aptosClient.GetResourceByAccountAddressAndResourceType(
		ctx,
		user.ToHex(),
		fmt.Sprintf("0x1::coin::CoinStore<%s>", "0x1::aptos_coin::AptosCoin"),
	)
	if err != nil {
		panic(fmt.Errorf("get user balance error: %v", err))
	}

	printCoinRes(userBalance)
}

func mintShovel(client client.AptosClient, aa models.AccountAddress) (*client.TransactionResp, error) {
	accountInfo, err := aptosClient.GetAccount(ctx, aa.ToHex())
	if err != nil {
		return nil, fmt.Errorf("get account error: %v", err)
	}
	tx := models.Transaction{}

	err = tx.SetChainID(ChainID).
		SetSender(aa.ToHex()).
		SetPayload(models.EntryFunctionPayload{
			Module:    Urn2EarnModule,
			Function:  "mint_shovel",
			Arguments: []interface{}{},
		}).
		SetExpirationTimestampSecs(uint64(time.Now().Add(30 * time.Second).Unix())).
		SetGasUnitPrice(GasPrice).
		SetMaxGasAmount(DefaultMaxGasAmount).
		SetSequenceNumber(accountInfo.SequenceNumber).Error()

	if err != nil {
		return nil, fmt.Errorf("build tx error: %v", err)
	}

	seed, err := hex.DecodeString(UserSeed)
	if err != nil {
		return nil, fmt.Errorf("decode seed error: %v", err)
	}
	sender := models.NewSingleSigner(ed25519.NewKeyFromSeed(seed))
	if err := sender.Sign(&tx).Error(); err != nil {
		return nil, fmt.Errorf("sign tx error: %v", err)
	}

	txResp, err := client.SubmitTransaction(ctx, tx.UserTransaction)
	if err != nil {
		return nil, fmt.Errorf("submit tx error: %w", err)
	}

	return txResp, nil
}

func printCoinRes(ar *client.AccountResource) {
	fmt.Println(ar.Type)
	b, _ := strconv.ParseFloat(ar.Data.CoinStoreResource.Coin.Value, 64)
	fmt.Println("Balance: ", b/Decimal)
}
