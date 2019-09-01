package slashing

import (
	"github.com/ipxchain/ipxchain/codec"
)

// Register concrete types on codec codec
func RegisterCodec(cdc *codec.Codec) {
	cdc.RegisterConcrete(MsgUnjail{}, "ipxchain/MsgUnjail", nil)
}

var cdcEmpty = codec.New()
