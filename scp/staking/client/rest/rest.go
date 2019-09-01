package rest

import (
	"github.com/ipxchain/ipxchain/client/context"
	"github.com/ipxchain/ipxchain/codec"
	"github.com/ipxchain/ipxchain/crypto/keys"

	"github.com/gorilla/mux"
)

// RegisterRoutes registers staking-related REST handlers to a router
func RegisterRoutes(cliCtx context.CLIContext, r *mux.Router, cdc *codec.Codec, kb keys.Keybase) {
	registerQueryRoutes(cliCtx, r, cdc)
	registerTxRoutes(cliCtx, r, cdc, kb)
}
