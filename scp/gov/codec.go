package gov

import (
	"github.com/ipxchain/ipxchain/codec"
)

var msgCdc = codec.New()

// Register concrete types on codec codec
func RegisterCodec(cdc *codec.Codec) {
	cdc.RegisterConcrete(MsgSubmitProposal{}, "ipxchain/MsgSubmitProposal", nil)
	cdc.RegisterConcrete(MsgDeposit{}, "ipxchain/MsgDeposit", nil)
	cdc.RegisterConcrete(MsgVote{}, "ipxchain/MsgVote", nil)

	cdc.RegisterInterface((*Proposal)(nil), nil)
	cdc.RegisterConcrete(&TextProposal{}, "gov/TextProposal", nil)
}

func init() {
	RegisterCodec(msgCdc)
}
