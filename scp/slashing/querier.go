package slashing

import (
	abci "github.com/tendermint/tendermint/abci/types"

	"github.com/ipxchain/ipxchain/codec"
	sdk "github.com/ipxchain/ipxchain/types"
)

// Query endpoints supported by the slashing querier
const (
	QueryParameters = "parameters"
)

// NewQuerier creates a new querier for slashing clients.
func NewQuerier(k Keeper, cdc *codec.Codec) sdk.Querier {
	return func(ctx sdk.Context, path []string, req abci.RequestQuery) ([]byte, sdk.Error) {
		switch path[0] {
		case QueryParameters:
			return queryParams(ctx, cdc, k)
		default:
			return nil, sdk.ErrUnknownRequest("unknown staking query endpoint")
		}
	}
}

func queryParams(ctx sdk.Context, cdc *codec.Codec, k Keeper) ([]byte, sdk.Error) {
	params := k.GetParams(ctx)

	res, err := codec.MarshalJSONIndent(cdc, params)
	if err != nil {
		return nil, sdk.ErrInternal(sdk.AppendMsgToErr("failed to marshal JSON", err.Error()))
	}

	return res, nil
}
