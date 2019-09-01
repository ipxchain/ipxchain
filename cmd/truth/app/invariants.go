package app

import (
	"fmt"
	"time"

	abci "github.com/tendermint/tendermint/abci/types"

	sdk "github.com/ipxchain/ipxchain/types"
	banksim "github.com/ipxchain/ipxchain/scp/bank/simulation"
	distrsim "github.com/ipxchain/ipxchain/scp/distribution/simulation"
	stakingsim "github.com/ipxchain/ipxchain/scp/staking/simulation"
)

func (app *GaiaApp) runtimeInvariants() []sdk.Invariant {
	return []sdk.Invariant{
		banksim.NonnegativeBalanceInvariant(app.accountKeeper),
		distrsim.NonNegativeOutstandingInvariant(app.distrKeeper),
		stakingsim.SupplyInvariants(app.stakingKeeper, app.feeCollectionKeeper, app.distrKeeper, app.accountKeeper),
		stakingsim.NonNegativePowerInvariant(app.stakingKeeper),
	}
}

func (app *GaiaApp) assertRuntimeInvariants() {
	ctx := app.NewContext(false, abci.Header{Height: app.LastBlockHeight() + 1})
	app.assertRuntimeInvariantsOnContext(ctx)
}

func (app *GaiaApp) assertRuntimeInvariantsOnContext(ctx sdk.Context) {
	start := time.Now()
	invariants := app.runtimeInvariants()
	for _, inv := range invariants {
		if err := inv(ctx); err != nil {
			panic(fmt.Errorf("invariant broken: %s", err))
		}
	}
	end := time.Now()
	diff := end.Sub(start)
	app.BaseApp.Logger().With("module", "invariants").Info("Asserted all invariants", "duration", diff)
}
