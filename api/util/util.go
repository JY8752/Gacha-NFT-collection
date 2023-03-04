package util

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"time"

	"github.com/onflow/cadence"
	jsoncdc "github.com/onflow/cadence/encoding/json"
	"github.com/onflow/cadence/runtime/sema"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/access"
	"github.com/onflow/flow-go-sdk/crypto"
)

const configPath = "../flow.json"

var conf config

type config struct {
	Accounts struct {
		Service struct {
			Address string `json:"address"`
			Key     string `json:"key"`
		} `json:"emulator-account"`
	}
	Contracts map[string]string `json:"contracts"`
}

func init() {
	// confの読み込み
	f, err := os.Open(configPath)
	ErrorHandle(err)

	err = json.NewDecoder(f).Decode(&conf)
	ErrorHandle(err)
}

func ErrorHandle(err error) {
	if err != nil {
		fmt.Println("err: ", err.Error())
		panic(err)
	}
}

// emulator-account情報の読み込み
// addr: emulator-accountのアドレス
// accountKey: emulator-accountの公開鍵
// signer: 署名者
func ServiceAccount(flowClient access.Client) (flow.Address, *flow.AccountKey, crypto.Signer) {
	// 秘密鍵
	privateKey, err := crypto.DecodePrivateKeyHex(crypto.ECDSA_P256, conf.Accounts.Service.Key)
	ErrorHandle(err)

	// アカウント情報
	addr := flow.HexToAddress(conf.Accounts.Service.Address)
	acc, err := flowClient.GetAccount(context.Background(), addr)
	ErrorHandle(err)

	accountKey := acc.Keys[0]
	signer, err := crypto.NewInMemorySigner(privateKey, accountKey.HashAlgo)
	ErrorHandle(err)

	return addr, accountKey, signer
}

// ECDSA P-256秘密鍵を生成する
func RandomPrivateKey() crypto.PrivateKey {
	seed := make([]byte, crypto.MinSeedLength)
	_, err := rand.Read(seed)
	ErrorHandle(err)

	privateKey, err := crypto.GeneratePrivateKey(crypto.ECDSA_P256, seed)
	ErrorHandle(err)

	return privateKey
}

// 最新のブロックIdを取得
func GetReferenceBlockId(flowClient access.Client) flow.Identifier {
	block, err := flowClient.GetLatestBlock(context.Background(), true)
	ErrorHandle(err)

	return block.ID
}

// トランザクションが完全に完了しブロックに取り込まれるまで待つ
func WaitForSeal(ctx context.Context, c access.Client, id flow.Identifier) *flow.TransactionResult {
	result, err := c.GetTransactionResult(ctx, id)
	ErrorHandle(err)

	fmt.Printf("Waiting for transaction %s to be sealed...\n", id)

	for result.Status != flow.TransactionStatusSealed {
		time.Sleep(time.Second)
		fmt.Print(".")
		result, err = c.GetTransactionResult(ctx, id)
		ErrorHandle(err)
	}

	fmt.Println()
	fmt.Printf("Transaction %s sealed\n", id)

	// エラー出るので問答無用で待つ
	time.Sleep(5 * time.Second)

	return result
}

// アカウントにFLOWをmintする。emulator環境のみ
func FundAccountInEmulator(flowClient access.Client, address flow.Address, amount float64) {
	serviceAddr, serviceAccountKey, serviceSigner := ServiceAccount(flowClient)

	referenceBlockId := GetReferenceBlockId(flowClient)

	fungibleTokenAddress := flow.HexToAddress(conf.Contracts["FungibleToken"])
	flowTokenAddress := flow.HexToAddress(conf.Contracts["FlowToken"])

	recipient := cadence.NewAddress(address)
	uintAmouont := uint64(amount * sema.Fix64Factor)
	cadenceAmount := cadence.UFix64(uintAmouont)

	// FLOWトークンミント用のトランザクション
	fundAmouontTx := flow.NewTransaction().
		SetScript([]byte(fmt.Sprintf(mintTokensToAccountTemplate, fungibleTokenAddress, flowTokenAddress))).
		AddAuthorizer(serviceAddr).
		AddRawArgument(jsoncdc.MustEncode(recipient)).
		AddRawArgument(jsoncdc.MustEncode(cadenceAmount)).
		SetProposalKey(serviceAddr, serviceAccountKey.Index, serviceAccountKey.SequenceNumber).
		SetReferenceBlockID(referenceBlockId).
		SetPayer(serviceAddr)

	err := fundAmouontTx.SignEnvelope(serviceAddr, serviceAccountKey.Index, serviceSigner)
	ErrorHandle(err)

	ctx := context.Background()
	err = flowClient.SendTransaction(ctx, *fundAmouontTx)
	ErrorHandle(err)

	result := WaitForSeal(ctx, flowClient, fundAmouontTx.ID())
	ErrorHandle(result.Error)
}

func ReadFile(path string) string {
	contents, err := ioutil.ReadFile(path)
	ErrorHandle(err)

	return string(contents)
}

// FLOWトークンmint用のトランザクションテンプレート
var mintTokensToAccountTemplate = `
	import FungibleToken from 0x%s
	import FlowToken from 0x%s
	transaction(recipient: Address, amount: UFix64) {
		let tokenAdmin: &FlowToken.Administrator
		let tokenReceiver: &{FungibleToken.Receiver}
		prepare(signer: AuthAccount) {
			self.tokenAdmin = signer
				.borrow<&FlowToken.Administrator>(from: /storage/flowTokenAdmin)
				?? panic("Signer is not the token admin")
			self.tokenReceiver = getAccount(recipient)
				.getCapability(/public/flowTokenReceiver)
				.borrow<&{FungibleToken.Receiver}>()
				?? panic("Unable to borrow receiver reference")
		}
		execute {
			let minter <- self.tokenAdmin.createNewMinter(allowedAmount: amount)
			let mintedVault <- minter.mintTokens(amount: amount)
			self.tokenReceiver.deposit(from: <-mintedVault)
			destroy minter
		}
	}
`
