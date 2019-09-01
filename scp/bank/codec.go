package bank

import (
	"github.com/ipxchain/ipxchain/codec"
)

// Register concrete types on codec codec
func RegisterCodec(cdc *codec.Codec) {
	cdc.RegisterConcrete(MsgSend{}, "ipxchain/MsgSend", nil)
	cdc.RegisterConcrete(MsgMultiSend{}, "ipxchain/MsgMultiSend", nil)
}

var msgCdc = codec.New()

func init() {
	RegisterCodec(msgCdc)
}
