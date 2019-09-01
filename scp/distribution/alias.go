// nolint
package distribution

import (
	"github.com/ipxchain/ipxchain/scp/distribution/keeper"
	"github.com/ipxchain/ipxchain/scp/distribution/tags"
	"github.com/ipxchain/ipxchain/scp/distribution/types"
)

type (
	Keeper = keeper.Keeper
	Hooks  = keeper.Hooks

	MsgSetWithdrawAddress          = types.MsgSetWithdrawAddress
	MsgWithdrawDelegatorReward     = types.MsgWithdrawDelegatorReward
	MsgWithdrawValidatorCommission = types.MsgWithdrawValidatorCommission

	GenesisState = types.GenesisState

	// expected keepers
	StakingKeeper       = types.StakingKeeper
	BankKeeper          = types.BankKeeper
	FeeCollectionKeeper = types.FeeCollectionKeeper

	// querier param types
	QueryValidatorCommissionParams   = keeper.QueryValidatorCommissionParams
	QueryValidatorSlashesParams      = keeper.QueryValidatorSlashesParams
	QueryDelegationRewardsParams     = keeper.QueryDelegationRewardsParams
	QueryDelegatorWithdrawAddrParams = keeper.QueryDelegatorWithdrawAddrParams
)

const (
	DefaultCodespace = types.DefaultCodespace
	CodeInvalidInput = types.CodeInvalidInput
	StoreKey         = types.StoreKey
	TStoreKey        = types.TStoreKey
	RouterKey        = types.RouterKey
	QuerierRoute     = types.QuerierRoute
)

var (
	ErrNilDelegatorAddr = types.ErrNilDelegatorAddr
	ErrNilWithdrawAddr  = types.ErrNilWithdrawAddr
	ErrNilValidatorAddr = types.ErrNilValidatorAddr

	TagValidator = tags.Validator
	TagDelegator = tags.Delegator

	NewMsgSetWithdrawAddress          = types.NewMsgSetWithdrawAddress
	NewMsgWithdrawDelegatorReward     = types.NewMsgWithdrawDelegatorReward
	NewMsgWithdrawValidatorCommission = types.NewMsgWithdrawValidatorCommission

	NewKeeper                                 = keeper.NewKeeper
	NewQuerier                                = keeper.NewQuerier
	NewQueryValidatorOutstandingRewardsParams = keeper.NewQueryValidatorOutstandingRewardsParams
	NewQueryValidatorCommissionParams         = keeper.NewQueryValidatorCommissionParams
	NewQueryValidatorSlashesParams            = keeper.NewQueryValidatorSlashesParams
	NewQueryDelegationRewardsParams           = keeper.NewQueryDelegationRewardsParams
	NewQueryDelegatorParams                   = keeper.NewQueryDelegatorParams
	NewQueryDelegatorWithdrawAddrParams       = keeper.NewQueryDelegatorWithdrawAddrParams
	DefaultParamspace                         = keeper.DefaultParamspace

	RegisterCodec       = types.RegisterCodec
	DefaultGenesisState = types.DefaultGenesisState
	ValidateGenesis     = types.ValidateGenesis
	InitialFeePool      = types.InitialFeePool
)
