package main

import (
	"context"
	"fmt"

	"github.com/JY8752/flow-go-sdk-example/util"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/access/http"
	"github.com/onflow/flow-go-sdk/crypto"
	"github.com/onflow/flow-go-sdk/templates"
)

const CALCULATE_CONTRACT = "../calculate.cdc"

func main() {
	// emulatorと接続
	ctx := context.Background()
	flowClient, err := http.NewClient(http.EmulatorHost)
	util.ErrorHandle(err)

	// emulator
	serviceAddr, serviceKey, serviceSigner := util.ServiceAccount(flowClient)

	// 鍵
	myPrivateKey := util.RandomPrivateKey()
	myAccounteky := flow.NewAccountKey().
		FromPrivateKey(myPrivateKey).
		SetHashAlgo(crypto.SHA3_256).
		SetWeight(flow.AccountKeyWeightThreshold)
	_, err = crypto.NewInMemorySigner(myPrivateKey, myAccounteky.HashAlgo)
	util.ErrorHandle(err)

	// アカウント作成トランザクション
	referenceBlockId := util.GetReferenceBlockId(flowClient)
	createAccountTx, err := templates.CreateAccount([]*flow.AccountKey{myAccounteky}, nil, serviceAddr)
	util.ErrorHandle(err)
	createAccountTx.SetProposalKey(
		serviceAddr,
		serviceKey.Index,
		serviceKey.SequenceNumber,
	)
	createAccountTx.SetReferenceBlockID(referenceBlockId)
	createAccountTx.SetPayer(serviceAddr)

	// 署名
	err = createAccountTx.SignEnvelope(serviceAddr, serviceKey.Index, serviceSigner)
	util.ErrorHandle(err)

	// send
	err = flowClient.SendTransaction(ctx, *createAccountTx)
	util.ErrorHandle(err)

	// 取り込まれるまで待機
	accountCreationTxRes := util.WaitForSeal(ctx, flowClient, createAccountTx.ID())
	util.ErrorHandle(accountCreationTxRes.Error)

	// トランザクション成功
	serviceKey.SequenceNumber++

	// イベントから作成したアドレス取得
	var myAddress flow.Address
	for _, event := range accountCreationTxRes.Events {
		if event.Type == flow.EventAccountCreated {
			myAddress = flow.AccountCreatedEvent(event).Address()
		}
	}

	fmt.Println("myAddress: ", myAddress.Hex())

	// FLOWトークンをミント
	util.FundAccountInEmulator(flowClient, myAddress, 100.0)
	serviceKey.SequenceNumber++

	// コントラクトデプロイ
	calculateCode := util.ReadFile(CALCULATE_CONTRACT)
	deployContractTx, err := templates.CreateAccount(
		nil,
		[]templates.Contract{
			{
				Name:   "Calculate",
				Source: calculateCode,
			},
		},
		serviceAddr,
	)
	util.ErrorHandle(err)

	deployContractTx.
		SetProposalKey(
			serviceAddr,
			serviceKey.Index,
			serviceKey.SequenceNumber,
		).
		SetReferenceBlockID(referenceBlockId).
		SetPayer(serviceAddr)

	err = deployContractTx.SignEnvelope(serviceAddr, serviceKey.Index, serviceSigner)
	util.ErrorHandle(err)

	err = flowClient.SendTransaction(ctx, *deployContractTx)
	util.ErrorHandle(err)

	deployContractTxResp := util.WaitForSeal(ctx, flowClient, deployContractTx.ID())
	util.ErrorHandle(deployContractTxResp.Error)

	// トランザクション成功
	serviceKey.SequenceNumber++

	var calculateAddress flow.Address
	for _, event := range deployContractTxResp.Events {
		if event.Type == flow.EventAccountCreated {
			calculateAddress = flow.AccountCreatedEvent(event).Address()
		}
	}

	fmt.Println("calculate Address: ", calculateAddress.Hex())

	// スクリプト実行
	result, err := flowClient.ExecuteScriptAtLatestBlock(ctx, generateAddScript(calculateAddress), []cadence.Value{
		cadence.NewInt64(1),
		cadence.NewInt64(1),
	})
	util.ErrorHandle(err)

	fmt.Printf("script complete!! result is %v\n", result)
}

// add関数を実行するscript
func generateAddScript(calculateAddress flow.Address) []byte {
	template := `
		import Calculate from 0x%s

		pub fun main(num1: Int64, num2: Int64): Int64 {
			return Calculate.add(num1, num2)
		}
	`

	return []byte(fmt.Sprintf(template, calculateAddress))
}
