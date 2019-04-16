# crowdfunding-demo

This demo is able to do the following:
* execute in the web repl Pact.kadena.io
* One user is able to set up a smart contract crowdfunding campaign with:
    * Target amount to raise (denominated in Kadena Coin)
    * Date or time the target must be hit by

Smart contract functions:
* User able to initiate with own balance
* Escrow payment from any user (using Pacts)
* Have conditionality where if target is not reached by date, the smart contract returns the funds to all users who submitted
