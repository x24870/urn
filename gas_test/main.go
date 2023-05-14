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
const OwnerAddr = "c9e7e612afec0ebf928da3a0f297ae53d3598d7d33cfac7b1072a605dd672961"
const UserAddr = "7f3994fea07933ad0ee7e91a8494cbdaadb1c486a10d7ae79192d79befc27b4b"
const UserSeed = "0b2374d9d786fa18aa7363f0a56b40bd6b00309c857a5658681f168e77bfb602"

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
	// printAccountTokens(user)

	// do 10 times
	// for i := 0; i < 10; i++ {
	// 	mintShovelDig()
	// }

	// resp, err := mint(aptosClient, user, "shovel")
	// resp, err := mint(aptosClient, user, "urn")
	// resp, err = dig(aptosClient, user)
	resp, err := putBonePart(aptosClient, user, "arm")
	if err != nil {
		panic(fmt.Errorf("error: %v", err))
	}
	aptosClient.WaitForTransaction(ctx, resp.Hash)

	// printAccountTokens(user)
}

// pretty print account tokens
func printAccountTokens(a models.AccountAddress) {
	tokens, err := tokenClient.ListAccountTokens(ctx, a)
	if err != nil {
		panic(err)
	}
	for _, t := range tokens {
		if t.ID.Collection != "urn" {
			continue
		}
		fmt.Printf("%s: %d\n", t.ID.Name, t.Amount)
		for k, v := range t.JSONProperties {
			if k == "point" || k == "ash" {
				fmt.Printf("  point: %s\n", v)
			}
		}
	}
}

func putBonePart(client client.AptosClient, aa models.AccountAddress, part string) (*client.TransactionResp, error) {
	tokens, err := tokenClient.ListAccountTokens(ctx, aa)
	if err != nil {
		return nil, fmt.Errorf("tokenClient.ListAccountTokens error: %v", err)
	}

	var boneToken models.TokenID
	for _, t := range tokens {
		if t.ID.Name == part {
			boneToken = t.ID
		}
	}
	if boneToken.Name != part {
		return nil, fmt.Errorf("no bone token found")
	}
	fmt.Printf("boneToken: %+v\n", boneToken)

	var urnToken models.TokenID
	for _, t := range tokens {
		if t.ID.Name == "urn" {
			urnToken = t.ID
		}
	}
	fmt.Printf("urnToken: %+v\n", urnToken)

	accountInfo, err := aptosClient.GetAccount(ctx, aa.ToHex())
	if err != nil {
		panic(fmt.Errorf("aptosClient.GetAccount error: %v", err))
	}

	var tx models.Transaction
	err = tx.SetChainID(ChainID).
		SetSender(aa.ToHex()).
		SetPayload(models.EntryFunctionPayload{
			Module:   Urn2EarnModule,
			Function: "burn_and_fill",
			Arguments: []interface{}{
				uint64(urnToken.PropertyVersion),
				uint64(boneToken.PropertyVersion),
				part,
			},
		}).
		SetExpirationTimestampSecs(uint64(time.Now().Add(30 * time.Second).Unix())).
		SetGasUnitPrice(GasPrice).
		SetMaxGasAmount(DefaultMaxGasAmount).
		SetSequenceNumber(accountInfo.SequenceNumber).Error()
	if err != nil {
		return nil, fmt.Errorf("set tx error: %v", err)
	}

	seed, err := hex.DecodeString(UserSeed)
	if err != nil {
		return nil, fmt.Errorf("decode seed error: %v", err)
	}
	sender := models.NewSingleSigner(ed25519.NewKeyFromSeed(seed))
	if err := sender.Sign(&tx).Error(); err != nil {
		return nil, fmt.Errorf("sign tx error: %v", err)
	}

	_, err = client.SimulateTransaction(ctx, tx.UserTransaction, false, false)
	if err != nil {
		return nil, fmt.Errorf("simulate tx error: %w", err)
	}

	txResp, err := client.SubmitTransaction(ctx, tx.UserTransaction)
	if err != nil {
		return nil, fmt.Errorf("submit tx error: %w", err)
	}

	return txResp, nil
}

func mintShovelDig() {
	printBalance()
	ob := getBalance(owner)
	ub := getBalance(user)

	txResp, err := mint(aptosClient, user, "shovel")
	if err != nil {
		panic(fmt.Errorf("mint shovel error: %v", err))
	}
	aptosClient.WaitForTransaction(ctx, txResp.Hash)

	fmt.Println("mint shovel success")
	fmt.Printf("owner balance diff %f\n", (getBalance(owner)-ob)/Decimal)
	fmt.Printf("user balance diff %f\n", (getBalance(user)-ub)/Decimal)

	digResp, err := dig(aptosClient, user)
	if err != nil {
		panic(fmt.Errorf("dig error: %v", err))
	}
	aptosClient.WaitForTransaction(ctx, digResp.Hash)

	fmt.Println("dig success")
	fmt.Printf("owner balance diff %f\n", (getBalance(owner)-ob)/Decimal)
	fmt.Printf("user balance diff %f\n", (getBalance(user)-ub)/Decimal)
	printBalance()
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

func dig(client client.AptosClient, aa models.AccountAddress) (*client.TransactionResp, error) {
	accountInfo, err := aptosClient.GetAccount(ctx, aa.ToHex())
	if err != nil {
		return nil, fmt.Errorf("get account error: %v", err)
	}
	tx := models.Transaction{}

	err = tx.SetChainID(ChainID).
		SetSender(aa.ToHex()).
		SetPayload(models.EntryFunctionPayload{
			Module:    Urn2EarnModule,
			Function:  "dig",
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

func mint(client client.AptosClient, aa models.AccountAddress, obj string) (*client.TransactionResp, error) {
	accountInfo, err := aptosClient.GetAccount(ctx, aa.ToHex())
	if err != nil {
		return nil, fmt.Errorf("get account error: %v", err)
	}
	tx := models.Transaction{}

	var fn string
	switch obj {
	case "shovel":
		fn = "mint_shovel"
	case "urn":
		fn = "mint_urn"
	default:
		return nil, fmt.Errorf("unknown obj %s", obj)
	}

	err = tx.SetChainID(ChainID).
		SetSender(aa.ToHex()).
		SetPayload(models.EntryFunctionPayload{
			Module:    Urn2EarnModule,
			Function:  fn,
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
