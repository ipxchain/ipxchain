package rest

import (
	"net/http"

	"github.com/ipxchain/ipxchain/client/context"
	clientrest "github.com/ipxchain/ipxchain/client/rest"
	"github.com/ipxchain/ipxchain/codec"
	"github.com/ipxchain/ipxchain/crypto/keys"
	sdk "github.com/ipxchain/ipxchain/types"
	"github.com/ipxchain/ipxchain/types/rest"
	"github.com/ipxchain/ipxchain/scp/switch"

	"github.com/gorilla/mux"
)

// RegisterRoutes - Central function to define routes that get registered by the main application
func RegisterRoutes(cliCtx context.CLIContext, r *mux.Router, cdc *codec.Codec, kb keys.Keybase) {
	r.HandleFunc("/ibc/{destchain}/{address}/send", TransferRequestHandlerFn(cdc, kb, cliCtx)).Methods("POST")
}

type transferReq struct {
	BaseReq rest.BaseReq `json:"base_req"`
	Amount  sdk.Coins    `json:"amount"`
}

// TransferRequestHandler - http request handler to transfer coins to a address
// on a different chain via IBC.
func TransferRequestHandlerFn(cdc *codec.Codec, kb keys.Keybase, cliCtx context.CLIContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		vars := mux.Vars(r)
		destChainID := vars["destchain"]
		bech32Addr := vars["address"]

		to, err := sdk.AccAddressFromBech32(bech32Addr)
		if err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}

		var req transferReq
		if !rest.ReadRESTReq(w, r, cdc, &req) {
			return
		}

		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		from, err := sdk.AccAddressFromBech32(req.BaseReq.From)
		if err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}

		packet := ibc.NewIBCPacket(from, to, req.Amount, req.BaseReq.ChainID, destChainID)
		msg := ibc.MsgIBCTransfer{IBCPacket: packet}

		clientrest.WriteGenerateStdTxResponse(w, cdc, cliCtx, req.BaseReq, []sdk.Msg{msg})
	}
}
