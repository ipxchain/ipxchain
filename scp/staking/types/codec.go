package types

import (
	"github.com/ipxchain/ipxchain/codec"
)

// Register concrete types on codec codec
func RegisterCodec(cdc *codec.Codec) {
	cdc.RegisterConcrete(MsgCreateValidator{}, "ipxchain/MsgCreateValidator", nil)
	cdc.RegisterConcrete(MsgEditValidator{}, "ipxchain/MsgEditValidator", nil)
	cdc.RegisterConcrete(MsgDelegate{}, "ipxchain/MsgDelegate", nil)
	cdc.RegisterConcrete(MsgUndelegate{}, "ipxchain/MsgUndelegate", nil)
	cdc.RegisterConcrete(MsgBeginRedelegate{}, "ipxchain/MsgBeginRedelegate", nil)
}

// generic sealed codec to be used throughout sdk
var MsgCdc *codec.Codec

func init() {
	cdc := codec.New()
	RegisterCodec(cdc)
	codec.RegisterCrypto(cdc)
	MsgCdc = cdc.Seal()
}
