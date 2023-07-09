package main

import (
	"context"
	"crypto/ed25519"
	"encoding/hex"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/portto/aptos-go-sdk/client"
	"github.com/portto/aptos-go-sdk/models"
)

const ChainID = 2
const Decimal = 100000000
const CollectionName = "Aptos"
const TokenName = "Aptos Token"
const GasPrice = uint64(100)
const DefaultMaxGasAmount = uint64(500000)

const OwnerAddr = "56260c419e8b176e0ca7f6d439b69180c2de2cb284d8dee24476f247af204492"
const UserAddr = "b34c0314d90b2597f2531119601f4ad7fe9db4eb7671265e93c905a46aa92860"
const UserSeed = "fa5356d432ca2a11838cb6d644e392cf78c3eb7ed8a6148c6165944972cacfde"
const User2Addr = "0e138de41892cba07ad1be13880902c7b7a143b7e7fa044b52bb4c52b150d915"
const User2Seed = "eba9b94746377de1b644a2c11765dcfd7521f4218461aba724969463a8372f9a"
const HoardingAddr = "d27433714a8f3b701d951f8eeb6be1f7743354ef0aec278028f77d9a8f72da59"
const HoardingSeed = "82519badd7ec193a946d4ab3cb3b5d022c25c2a084d8d80606ae6ee826f3bac4"

var aptosClient client.AptosClient
var tokenClient client.TokenClient

var addr0x1 models.AccountAddress
var aptosCoinTypeTag models.TypeTag

var owner models.AccountAddress
var user models.AccountAddress
var user2 models.AccountAddress
var hoarding models.AccountAddress

var Urn2EarnModule models.Module
var KnifeModule models.Module

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

	KnifeModule = models.Module{
		Address: owner,
		Name:    "knife",
	}

	user, err = models.HexToAccountAddress(UserAddr)
	if err != nil {
		panic(fmt.Errorf("models.HexToAccountAddress error: %v", err))
	}

	user2, err = models.HexToAccountAddress(User2Addr)
	if err != nil {
		panic(fmt.Errorf("models.HexToAccountAddress error: %v", err))
	}

	hoarding, err = models.HexToAccountAddress(HoardingAddr)
	if err != nil {
		panic(fmt.Errorf("models.HexToAccountAddress error: %v", err))
	}
}

func main() {
	// printAccountTokens(user)

	// do 10 times
	// for i := 0; i < 100; i++ {
	// 	mintShovelDig(user2, HoardingSeed)
	// }

	// resp, err := mint(aptosClient, user2, User2Seed, "shovel")
	// resp, err := mint(aptosClient, user, UserSeed, "urn")
	// resp, err := mint(aptosClient, user2, User2Seed, "forge")
	// resp, err := dig(aptosClient, user2, User2Seed)
	// resp, err := putBonePart(aptosClient, user2, User2Seed, "golden hip", true)
	// resp, err := high_cost_func(aptosClient, user, UserSeed)
	resp, err := rob(aptosClient, user2, User2Seed, user)
	// resp, err := random_rob(aptosClient, user, UserSeed)
	if err != nil {
		panic(fmt.Errorf("error: %v", err))
	}
	aptosClient.WaitForTransaction(ctx, resp.Hash)

	fmt.Println("-------- transaction hash:", resp.Hash)
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

func create_rob_history_ressource(
	client client.AptosClient, user models.AccountAddress, seedStr string,
) (*client.TransactionResp, error) {
	accountInfo, err := aptosClient.GetAccount(ctx, user.ToHex())
	if err != nil {
		panic(fmt.Errorf("aptosClient.GetAccount error: %v", err))
	}

	var tx models.Transaction
	err = tx.SetChainID(ChainID).
		SetSender(user.ToHex()).
		SetPayload(models.EntryFunctionPayload{
			Module:    KnifeModule,
			Function:  "create_rob_history_manually",
			Arguments: []interface{}{},
		}).
		SetExpirationTimestampSecs(uint64(time.Now().Add(30 * time.Second).Unix())).
		SetGasUnitPrice(GasPrice).
		SetMaxGasAmount(DefaultMaxGasAmount).
		SetSequenceNumber(accountInfo.SequenceNumber).Error()
	if err != nil {
		return nil, fmt.Errorf("set tx error: %v", err)
	}

	seed, err := hex.DecodeString(seedStr)
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

func rob(
	client client.AptosClient, robber models.AccountAddress, seedStr string, victim models.AccountAddress,
) (*client.TransactionResp, error) {
	// get victom urn
	victimTokens, err := tokenClient.ListAccountTokens(ctx, victim)
	if err != nil {
		return nil, fmt.Errorf("tokenClient.ListAccountTokens error: %v", err)
	}

	var victimUrn models.TokenID
	curAsh := 0
	for _, t := range victimTokens {
		if t.ID.Name == "urn" {
			if ash, ok := t.JSONProperties["ash"]; ok {
				a, err := strconv.Atoi(ash)
				if err != nil {
					return nil, fmt.Errorf("strconv.Atoi error: %v", err)
				}
				if curAsh <= a {
					victimUrn = t.ID
				}
			}
		}
	}
	fmt.Printf("victimUrn: %+v\n", victimUrn)

	// get robbber urn
	robberTokens, err := tokenClient.ListAccountTokens(ctx, robber)
	if err != nil {
		return nil, fmt.Errorf("tokenClient.ListAccountTokens error: %v", err)
	}

	var robberUrn models.TokenID
	for _, t := range robberTokens {
		if t.ID.Name == "urn" {
			robberUrn = t.ID
		}
	}
	fmt.Printf("robberUrn: %+v\n", robberUrn)

	accountInfo, err := aptosClient.GetAccount(ctx, robber.ToHex())
	if err != nil {
		panic(fmt.Errorf("aptosClient.GetAccount error: %v", err))
	}

	var tx models.Transaction
	err = tx.SetChainID(ChainID).
		SetSender(robber.ToHex()).
		SetPayload(models.EntryFunctionPayload{
			Module:   Urn2EarnModule,
			Function: "rob",
			Arguments: []interface{}{
				uint64(robberUrn.PropertyVersion),
				victim,
				uint64(victimUrn.PropertyVersion),
				"hello world",
			},
		}).
		SetExpirationTimestampSecs(uint64(time.Now().Add(30 * time.Second).Unix())).
		SetGasUnitPrice(GasPrice).
		SetMaxGasAmount(DefaultMaxGasAmount).
		SetSequenceNumber(accountInfo.SequenceNumber).Error()
	if err != nil {
		return nil, fmt.Errorf("set tx error: %v", err)
	}

	seed, err := hex.DecodeString(seedStr)
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

func random_rob(
	client client.AptosClient, robber models.AccountAddress, seedStr string,
) (*client.TransactionResp, error) {
	// get robbber urn
	robberTokens, err := tokenClient.ListAccountTokens(ctx, robber)
	if err != nil {
		return nil, fmt.Errorf("tokenClient.ListAccountTokens error: %v", err)
	}

	var robberUrn models.TokenID
	for _, t := range robberTokens {
		if t.ID.Name == "urn" {
			robberUrn = t.ID
		}
	}
	fmt.Printf("robberUrn: %+v\n", robberUrn)

	accountInfo, err := aptosClient.GetAccount(ctx, robber.ToHex())
	if err != nil {
		panic(fmt.Errorf("aptosClient.GetAccount error: %v", err))
	}

	var tx models.Transaction
	err = tx.SetChainID(ChainID).
		SetSender(robber.ToHex()).
		SetPayload(models.EntryFunctionPayload{
			Module:   Urn2EarnModule,
			Function: "random_rob",
			Arguments: []interface{}{
				uint64(robberUrn.PropertyVersion),
				"Hello random guy",
			},
		}).
		SetExpirationTimestampSecs(uint64(time.Now().Add(30 * time.Second).Unix())).
		SetGasUnitPrice(GasPrice).
		SetMaxGasAmount(DefaultMaxGasAmount).
		SetSequenceNumber(accountInfo.SequenceNumber).Error()
	if err != nil {
		return nil, fmt.Errorf("set tx error: %v", err)
	}

	seed, err := hex.DecodeString(seedStr)
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

func putBonePart(
	client client.AptosClient, aa models.AccountAddress, seedStr, part string, is_golden bool,
) (*client.TransactionResp, error) {
	tokens, err := tokenClient.ListAccountTokens(ctx, aa)
	if err != nil {
		return nil, fmt.Errorf("tokenClient.ListAccountTokens error: %v", err)
	}

	if (is_golden && !strings.Contains(part, "golden")) || (!is_golden && strings.Contains(part, "golden")) {
		return nil, fmt.Errorf("invalid pard")
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
	var urnTokenName string
	if is_golden {
		urnTokenName = "golden_urn"
	} else {
		urnTokenName = "urn"
	}

	for _, t := range tokens {
		if t.ID.Name == urnTokenName {
			urnToken = t.ID
		}
	}
	fmt.Printf("urnToken: %+v\n", urnToken)

	accountInfo, err := aptosClient.GetAccount(ctx, aa.ToHex())
	if err != nil {
		panic(fmt.Errorf("aptosClient.GetAccount error: %v", err))
	}

	var tx models.Transaction
	var funcName string
	if is_golden {
		funcName = "burn_and_fill_golden"
	} else {
		funcName = "burn_and_fill"
	}
	err = tx.SetChainID(ChainID).
		SetSender(aa.ToHex()).
		SetPayload(models.EntryFunctionPayload{
			Module:   Urn2EarnModule,
			Function: funcName,
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

	seed, err := hex.DecodeString(seedStr)
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

func mintShovelDig(user models.AccountAddress, seedStr string) {
	// printBalance()
	// ob := getBalance(owner)
	// ub := getBalance(user)

	txResp, err := mint(aptosClient, user, seedStr, "shovel")
	if err != nil {
		fmt.Println(fmt.Errorf("mint shovel error: %v", err))
		return
	}
	aptosClient.WaitForTransaction(ctx, txResp.Hash)

	fmt.Println("mint shovel success")
	// fmt.Printf("owner balance diff %f\n", (getBalance(owner)-ob)/Decimal)
	// fmt.Printf("user balance diff %f\n", (getBalance(user)-ub)/Decimal)

	digResp, err := dig(aptosClient, user, seedStr)
	if err != nil {
		fmt.Println(fmt.Errorf("dig error: %v", err))
		return
	}
	aptosClient.WaitForTransaction(ctx, digResp.Hash)

	fmt.Println("dig success")
	aptosClient.WaitForTransaction(ctx, digResp.Hash)
	// fmt.Printf("owner balance diff %f\n", (getBalance(owner)-ob)/Decimal)
	// fmt.Printf("user balance diff %f\n", (getBalance(user)-ub)/Decimal)
	// printBalance()
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

func dig(client client.AptosClient, aa models.AccountAddress, seedStr string) (*client.TransactionResp, error) {
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

	seed, err := hex.DecodeString(seedStr)
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

func mint(client client.AptosClient, aa models.AccountAddress, seedStr, obj string) (*client.TransactionResp, error) {
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
	case "forge":
		fn = "forge"
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

	seed, err := hex.DecodeString(seedStr)
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

func high_cost_func(client client.AptosClient, aa models.AccountAddress, seedStr string) (*client.TransactionResp, error) {
	accountInfo, err := aptosClient.GetAccount(ctx, aa.ToHex())
	if err != nil {
		return nil, fmt.Errorf("get account error: %v", err)
	}
	tx := models.Transaction{}

	err = tx.SetChainID(ChainID).
		SetSender(aa.ToHex()).
		SetPayload(models.EntryFunctionPayload{
			Module:    Urn2EarnModule,
			Function:  "high_cost_func",
			Arguments: []interface{}{},
		}).
		SetExpirationTimestampSecs(uint64(time.Now().Add(30 * time.Second).Unix())).
		SetGasUnitPrice(GasPrice).
		SetMaxGasAmount(DefaultMaxGasAmount).
		SetSequenceNumber(accountInfo.SequenceNumber).Error()

	if err != nil {
		return nil, fmt.Errorf("build tx error: %v", err)
	}

	seed, err := hex.DecodeString(seedStr)
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
