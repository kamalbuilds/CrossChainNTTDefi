package job_test

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/google/uuid"
	"github.com/lib/pq"
	"github.com/pelletier/go-toml"
	"github.com/stretchr/testify/require"
	"gopkg.in/guregu/null.v4"

	"github.com/smartcontractkit/sqlx"

	"github.com/smartcontractkit/chainlink/v2/core/internal/cltest"
	"github.com/smartcontractkit/chainlink/v2/core/internal/testutils"
	"github.com/smartcontractkit/chainlink/v2/core/internal/testutils/evmtest"
	"github.com/smartcontractkit/chainlink/v2/core/internal/testutils/pgtest"
	"github.com/smartcontractkit/chainlink/v2/core/services/chainlink"
	"github.com/smartcontractkit/chainlink/v2/core/services/job"
	"github.com/smartcontractkit/chainlink/v2/core/services/keystore"
	"github.com/smartcontractkit/chainlink/v2/core/services/keystore/chaintype"
	"github.com/smartcontractkit/chainlink/v2/core/services/ocr"
	evmrelay "github.com/smartcontractkit/chainlink/v2/core/services/relay/evm"
	"github.com/smartcontractkit/chainlink/v2/core/store/models"
)

const (
	ocrJobSpecTemplate = `
type               = "offchainreporting"
schemaVersion      = 1
contractAddress    = "%s"
p2pBootstrapPeers  = [
    "/dns4/chain.link/tcp/1234/p2p/16Uiu2HAm58SP7UL8zsnpeuwHfytLocaqgnyaYKP8wu7qRdrixLju",
]
p2pv2Bootstrappers = []
isBootstrapPeer    = false
keyBundleID        = "%s"
monitoringEndpoint = "chain.link:4321"
transmitterAddress = "%s"
observationTimeout = "10s"
blockchainTimeout  = "20s"
contractConfigTrackerSubscribeInterval = "2m"
contractConfigTrackerPollInterval = "1m"
contractConfigConfirmations = 3
observationSource = """
	%s
"""
`
	ocr2vrfJobSpecTemplate = `
type                 	= "offchainreporting2"
schemaVersion        	= 1
name                 	= "ocr2 vrf spec"
maxTaskDuration      	= "10s"
contractID           	= "%s"
ocrKeyBundleID       	= "%s"
relay                	= "evm"
pluginType           	= "ocr2vrf"
transmitterID        	= "%s"
forwardingAllowed       = %t

[relayConfig]
chainID              	= %d
fromBlock               = %d
sendingKeys             = [%s]

[pluginConfig]
dkgEncryptionPublicKey 	= "%s"
dkgSigningPublicKey    	= "%s"
dkgKeyID               	= "%s"
dkgContractAddress     	= "%s"

vrfCoordinatorAddress   = "%s"
linkEthFeedAddress     	= "%s"
`
	voterTurnoutDataSourceTemplate = `
// data source 1
ds1          [type=bridge name="%s"];
ds1_parse    [type=jsonparse path="data,result"];
ds1_multiply [type=multiply times=100];

// data source 2
ds2          [type=http method=POST url="%s" requestData="{\\"hi\\": \\"hello\\"}"];
ds2_parse    [type=jsonparse path="turnout"];
ds2_multiply [type=multiply times=100];

ds1 -> ds1_parse -> ds1_multiply -> answer1;
ds2 -> ds2_parse -> ds2_multiply -> answer1;

answer1 [type=median                      index=0];
answer2 [type=bridge name="%s" index=1];
`

	simpleFetchDataSourceTemplate = `
// data source 1
ds1          [type=http method=GET url="%s" allowunrestrictednetworkaccess="true"];
ds1_parse    [type=jsonparse path="USD" lax=%t];
ds1_multiply [type=multiply times=100];
ds1 -> ds1_parse -> ds1_multiply;
`
	minimalNonBootstrapTemplate = `
		type               = "offchainreporting"
		schemaVersion      = 1
		contractAddress    = "%s"
		p2pBootstrapPeers  = ["/dns4/chain.link/tcp/1234/p2p/16Uiu2HAm58SP7UL8zsnpeuwHfytLocaqgnyaYKP8wu7qRdrixLju"]
		isBootstrapPeer    = false
		transmitterAddress = "%s"
		keyBundleID = "%s"
		observationTimeout = "10s"
		observationSource = """
ds1          [type=http method=GET url="%s" allowunrestrictednetworkaccess="true" %s];
ds1_parse    [type=jsonparse path="USD" lax=true];
ds1 -> ds1_parse;
"""
`
	minimalBootstrapTemplate = `
		type               = "offchainreporting"
		schemaVersion      = 1
		contractAddress    = "%s"
		p2pBootstrapPeers  = []
		isBootstrapPeer    = true
`
	ocrJobSpecText = `
type               = "offchainreporting"
schemaVersion      = 1
contractAddress    = "%s"
p2pPeerID          = "%s"
p2pBootstrapPeers  = [
    "/dns4/chain.link/tcp/1234/p2p/16Uiu2HAm58SP7UL8zsnpeuwHfytLocaqgnyaYKP8wu7qRdrixLju",
]
p2pv2Bootstrappers = []
isBootstrapPeer    = false
keyBundleID        = "%s"
monitoringEndpoint = "chain.link:4321"
transmitterAddress = "%s"
observationTimeout = "10s"
blockchainTimeout  = "20s"
contractConfigTrackerSubscribeInterval = "2m"
contractConfigTrackerPollInterval = "1m"
contractConfigConfirmations = 3
observationSource = """
    // data source 1
    ds1          [type=bridge name="%s"];
    ds1_parse    [type=jsonparse path="one,two"];
    ds1_multiply [type=multiply times=1.23];

    // data source 2
    ds2          [type=http method=GET url="https://chain.link/voter_turnout/USA-2020" requestData="{\\"hi\\": \\"hello\\"}"];
    ds2_parse    [type=jsonparse path="three,four"];
    ds2_multiply [type=multiply times=4.56];

    ds1 -> ds1_parse -> ds1_multiply -> answer1;
    ds2 -> ds2_parse -> ds2_multiply -> answer1;

    answer1 [type=median                      index=0];
    answer2 [type=bridge name="%s" index=1];
"""
`
)

func makeOCRJobSpec(t *testing.T, transmitterAddress common.Address, b1, b2 string) *job.Job {
	t.Helper()

	peerID := cltest.DefaultP2PPeerID
	ocrKeyID := cltest.DefaultOCRKeyBundleID
	jobSpecText := fmt.Sprintf(ocrJobSpecText, testutils.NewAddress().Hex(), peerID, ocrKeyID, transmitterAddress.Hex(), b1, b2)

	dbSpec := job.Job{
		ExternalJobID: uuid.New(),
	}
	err := toml.Unmarshal([]byte(jobSpecText), &dbSpec)
	require.NoError(t, err)
	var ocrspec job.OCROracleSpec
	err = toml.Unmarshal([]byte(jobSpecText), &ocrspec)
	require.NoError(t, err)
	dbSpec.OCROracleSpec = &ocrspec

	return &dbSpec
}

// `require.Equal` currently has broken handling of `time.Time` values, so we have
// to do equality comparisons of these structs manually.
//
// https://github.com/stretchr/testify/issues/984
func compareOCRJobSpecs(t *testing.T, expected, actual job.Job) {
	require.NotNil(t, expected.OCROracleSpec)
	require.Equal(t, expected.OCROracleSpec.ContractAddress, actual.OCROracleSpec.ContractAddress)
	require.Equal(t, expected.OCROracleSpec.P2PBootstrapPeers, actual.OCROracleSpec.P2PBootstrapPeers)
	require.Equal(t, expected.OCROracleSpec.IsBootstrapPeer, actual.OCROracleSpec.IsBootstrapPeer)
	require.Equal(t, expected.OCROracleSpec.EncryptedOCRKeyBundleID, actual.OCROracleSpec.EncryptedOCRKeyBundleID)
	require.Equal(t, expected.OCROracleSpec.TransmitterAddress, actual.OCROracleSpec.TransmitterAddress)
	require.Equal(t, expected.OCROracleSpec.ObservationTimeout, actual.OCROracleSpec.ObservationTimeout)
	require.Equal(t, expected.OCROracleSpec.BlockchainTimeout, actual.OCROracleSpec.BlockchainTimeout)
	require.Equal(t, expected.OCROracleSpec.ContractConfigTrackerSubscribeInterval, actual.OCROracleSpec.ContractConfigTrackerSubscribeInterval)
	require.Equal(t, expected.OCROracleSpec.ContractConfigTrackerPollInterval, actual.OCROracleSpec.ContractConfigTrackerPollInterval)
	require.Equal(t, expected.OCROracleSpec.ContractConfigConfirmations, actual.OCROracleSpec.ContractConfigConfirmations)
}

func makeMinimalHTTPOracleSpec(t *testing.T, db *sqlx.DB, cfg chainlink.GeneralConfig, contractAddress, transmitterAddress, keyBundle, fetchUrl, timeout string) *job.Job {
	var ocrSpec = job.OCROracleSpec{
		P2PBootstrapPeers:                      pq.StringArray{},
		P2PV2Bootstrappers:                     pq.StringArray{},
		ObservationTimeout:                     models.Interval(10 * time.Second),
		BlockchainTimeout:                      models.Interval(20 * time.Second),
		ContractConfigTrackerSubscribeInterval: models.Interval(2 * time.Minute),
		ContractConfigTrackerPollInterval:      models.Interval(1 * time.Minute),
		ContractConfigConfirmations:            uint16(3),
	}
	var os = job.Job{
		Name:          null.NewString("a job", true),
		Type:          job.OffchainReporting,
		SchemaVersion: 1,
		ExternalJobID: uuid.New(),
	}
	s := fmt.Sprintf(minimalNonBootstrapTemplate, contractAddress, transmitterAddress, keyBundle, fetchUrl, timeout)
	keyStore := cltest.NewKeyStore(t, db, pgtest.NewQConfig(true))
	relayExtenders := evmtest.NewChainRelayExtenders(t, evmtest.TestChainOpts{DB: db, Client: evmtest.NewEthClientMockWithDefaultChain(t), GeneralConfig: cfg, KeyStore: keyStore.Eth()})
	legacyChains := evmrelay.NewLegacyChainsFromRelayerExtenders(relayExtenders)
	_, err := ocr.ValidatedOracleSpecToml(legacyChains, s)
	require.NoError(t, err)
	err = toml.Unmarshal([]byte(s), &os)
	require.NoError(t, err)
	err = toml.Unmarshal([]byte(s), &ocrSpec)
	require.NoError(t, err)
	os.OCROracleSpec = &ocrSpec
	return &os
}

func makeVoterTurnoutOCRJobSpec(t *testing.T, transmitterAddress common.Address, b1, b2 string) *job.Job {
	t.Helper()
	return MakeVoterTurnoutOCRJobSpecWithHTTPURL(t, transmitterAddress, "https://example.com/foo/bar", b1, b2)
}

func MakeVoterTurnoutOCRJobSpecWithHTTPURL(t *testing.T, transmitterAddress common.Address, httpURL, b1, b2 string) *job.Job {
	t.Helper()
	ocrKeyID := cltest.DefaultOCRKeyBundleID
	ds := fmt.Sprintf(voterTurnoutDataSourceTemplate, b1, httpURL, b2)
	voterTurnoutJobSpec := fmt.Sprintf(ocrJobSpecTemplate, testutils.NewAddress().Hex(), ocrKeyID, transmitterAddress.Hex(), ds)
	return makeOCRJobSpecFromToml(t, voterTurnoutJobSpec)
}

func makeSimpleFetchOCRJobSpecWithHTTPURL(t *testing.T, transmitterAddress common.Address, httpURL string, lax bool) *job.Job {
	t.Helper()
	ocrKeyID := cltest.DefaultOCRKeyBundleID
	ds := fmt.Sprintf(simpleFetchDataSourceTemplate, httpURL, lax)
	simpleFetchJobSpec := fmt.Sprintf(ocrJobSpecTemplate, testutils.NewAddress().Hex(), ocrKeyID, transmitterAddress.Hex(), ds)
	return makeOCRJobSpecFromToml(t, simpleFetchJobSpec)
}

func makeOCRJobSpecFromToml(t *testing.T, jobSpecToml string) *job.Job {
	t.Helper()

	id := uuid.New()
	var jb = job.Job{
		Name:          null.StringFrom(id.String()),
		ExternalJobID: id,
	}
	err := toml.Unmarshal([]byte(jobSpecToml), &jb)
	require.NoError(t, err)
	var ocrspec job.OCROracleSpec
	err = toml.Unmarshal([]byte(jobSpecToml), &ocrspec)
	require.NoError(t, err)
	if ocrspec.P2PV2Bootstrappers == nil {
		ocrspec.P2PV2Bootstrappers = pq.StringArray{}
	}
	jb.OCROracleSpec = &ocrspec

	return &jb
}

func makeOCR2VRFJobSpec(t testing.TB, ks keystore.Master, cfg chainlink.GeneralConfig,
	transmitter common.Address, chainID *big.Int, fromBlock uint64) *job.Job {
	t.Helper()

	useForwarders := false
	_, beacon := cltest.MustInsertRandomKey(t, ks.Eth())
	_, coordinator := cltest.MustInsertRandomKey(t, ks.Eth())
	_, feed := cltest.MustInsertRandomKey(t, ks.Eth())
	_, dkg := cltest.MustInsertRandomKey(t, ks.Eth())
	sendingKeys := fmt.Sprintf(`"%s"`, transmitter)
	kb, _ := ks.OCR2().Create(chaintype.EVM)

	vrfKey := make([]byte, 32)
	_, err := rand.Read(vrfKey)
	require.NoError(t, err)

	ocr2vrfJob := fmt.Sprintf(ocr2vrfJobSpecTemplate,
		beacon.String(),
		kb.ID(),
		"",
		useForwarders,
		chainID,
		fromBlock,
		sendingKeys,
		ks.DKGEncrypt(),
		ks.DKGSign(),
		hex.EncodeToString(vrfKey[:]),
		dkg.String(),
		coordinator.String(),
		feed.String(),
	)
	jobSpec := makeOCR2JobSpecFromToml(t, ocr2vrfJob)

	return jobSpec
}

func makeOCR2JobSpecFromToml(t testing.TB, jobSpecToml string) *job.Job {
	t.Helper()

	id := uuid.New()
	var jb = job.Job{
		Name:          null.StringFrom(id.String()),
		ExternalJobID: id,
	}
	err := toml.Unmarshal([]byte(jobSpecToml), &jb)
	require.NoError(t, err, jobSpecToml)
	var ocr2spec job.OCR2OracleSpec
	err = toml.Unmarshal([]byte(jobSpecToml), &ocr2spec)
	require.NoError(t, err)
	if ocr2spec.P2PV2Bootstrappers == nil {
		ocr2spec.P2PV2Bootstrappers = pq.StringArray{}
	}
	jb.OCR2OracleSpec = &ocr2spec

	return &jb
}
