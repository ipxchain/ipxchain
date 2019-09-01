package ibc

import (
	"github.com/ipxchain/ipxchain/codec"
)

// Register concrete types on codec codec
func RegisterCodec(cdc *codec.Codec) {
	cdc.RegisterConcrete(MsgIBCTransfer{}, "ipxchain/MsgIBCTransfer", nil)
	cdc.RegisterConcrete(MsgIBCReceive{}, "ipxchain/MsgIBCReceive", nil)
}
