package smoke

import (
	"context"
	"math/big"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/smartcontractkit/chainlink-testing-framework/utils"

	"github.com/smartcontractkit/chainlink/integration-tests/actions"
	"github.com/smartcontractkit/chainlink/integration-tests/docker/test_env"
)

func TestOCRBasic(t *testing.T) {
	t.Parallel()
	l := utils.GetTestLogger(t)

	env, err := test_env.NewCLTestEnvBuilder().
		WithGeth().
		WithMockServer(1).
		WithCLNodes(6).
		WithFunding(big.NewFloat(.1)).
		Build()
	require.NoError(t, err)
	t.Cleanup(func() {
		if err := env.Cleanup(); err != nil {
			l.Error().Err(err).Msg("Error cleaning up test environment")
		}
	})

	env.ParallelTransactions(true)

	nodeClients := env.GetAPIs()
	bootstrapNode, workerNodes := nodeClients[0], nodeClients[1:]

	linkTokenContract, err := env.ContractDeployer.DeployLinkTokenContract()
	require.NoError(t, err, "Deploying Link Token Contract shouldn't fail")

	ocrInstances, err := actions.DeployOCRContractsLocal(1, linkTokenContract, env.ContractDeployer, workerNodes, env.EVMClient)
	require.NoError(t, err)
	err = env.EVMClient.WaitForEvents()
	require.NoError(t, err, "Error waiting for events")

	err = actions.CreateOCRJobsLocal(ocrInstances, bootstrapNode, workerNodes, 5, env.MockServer.Client)
	require.NoError(t, err)

	err = actions.StartNewRound(1, ocrInstances, env.EVMClient)
	require.NoError(t, err)

	answer, err := ocrInstances[0].GetLatestAnswer(context.Background())
	require.NoError(t, err, "Getting latest answer from OCR contract shouldn't fail")
	require.Equal(t, int64(5), answer.Int64(), "Expected latest answer from OCR contract to be 5 but got %d", answer.Int64())

	err = actions.SetAllAdapterResponsesToTheSameValueLocal(10, ocrInstances, workerNodes, env.MockServer.Client)
	require.NoError(t, err)
	err = actions.StartNewRound(2, ocrInstances, env.EVMClient)
	require.NoError(t, err)

	answer, err = ocrInstances[0].GetLatestAnswer(context.Background())
	require.NoError(t, err, "Error getting latest OCR answer")
	require.Equal(t, int64(10), answer.Int64(), "Expected latest answer from OCR contract to be 10 but got %d", answer.Int64())
}
