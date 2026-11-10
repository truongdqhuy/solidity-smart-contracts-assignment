# Ownable and ProtectedVault

## Implementation

Source: `/contracts/04_Ownable.sol`, using the MIT license and Solidity `^0.8.34`. `/contracts/04_Bank.sol` was not modified.

`ProtectedVault is Ownable` inherits the public `owner` getter, the ownership-transfer function, and the `onlyOwner` modifier. On deployment, the inherited constructor sets the deployer as owner and emits `OwnershipTransferred(address(0), owner)`. Ownership transfers reject the zero address and emit the previous and new owner addresses.

The `onlyOwner` modifier centralizes `require(msg.sender == owner, "Not the owner")`. Applying it to both `transferOwnership` and `withdraw` removes duplicated access-control checks and keeps their authorization rule consistent. Anyone may call `deposit`.

## ETH handling and accounting

`deposit()` is `payable`, which allows the function to receive ETH through `msg.value`. The received value is already included in `address(this).balance` when the function executes, so assigning that balance to `treasure` records the updated funds, including any previously forced ETH.

`payable(to)` is different: it converts the recipient address to a payable address for the outgoing value-bearing call. It does not make the withdrawal function payable or grant the recipient permission to withdraw.

`withdraw` rejects a zero recipient and requires `amt <= address(this).balance`. Using the actual ETH balance, rather than relying on the private accounting variable, accommodates forced ETH. The balance guard also makes `address(this).balance - amt` safe from underflow.

The withdrawal follows checks-effects-interactions: validate authorization, recipient and funds; set `treasure` to the balance minus the withdrawal; then send ETH with `payable(to).call{value: amt}("")`. A failed call reverts the transaction, including the accounting update. `contractBalance()` returns the actual ETH balance.

`treasure` is a synchronized bookkeeping snapshot, not an independent withdrawal limit. Forced ETH can change the actual balance without executing a function, so the snapshot is refreshed on deposits and before withdrawals. ETH forced into the vault during an outgoing callback can leave that snapshot stale until the next operation; withdrawals remain guarded by the actual balance. This keeps the assignment simple without assuming all ETH arrives through `deposit`.

## Planned Ganache test — not executed

Use two funded Ganache accounts, account1 and account2. Record their starting balances and each mined transaction's actual gas fee (`gasUsed * effectiveGasPrice`). Deploy `ProtectedVault`, not just its `Ownable` base.

1. Account1 deploys `ProtectedVault`. Check that `owner()` is account1 and the initial ownership event records the zero address and account1.
2. Account1 calls `deposit()` with 1 ETH. Check that `contractBalance()` returns 1 ETH.
3. Account2 attempts `withdraw(account2, 1 ether)`. Expect a revert with `Not the owner` and no ETH movement out of the vault. If estimation blocks submission, no transaction is mined and no gas is charged; a failed transaction that is actually mined consumes gas.
4. Account1 calls `transferOwnership(account2)`. Check the new owner and ownership-transfer event.
5. Account2 calls `withdraw(account2, 1 ether)`. Check that the vault balance becomes zero and the withdrawal succeeds.
6. Compare final account balances with starting balances. Account1's net change should be minus 1 ETH and minus the deployment, deposit, and ownership-transfer gas fees. Account2's net change should be plus 1 ETH minus the successful withdrawal gas fee and any gas fee from a mined failed withdrawal. Read-only calls do not incur transaction gas fees.

Additional planned checks: reject zero-address ownership transfers and withdrawal recipients, reject withdrawals exceeding the actual vault balance, and confirm that a rejecting recipient causes the transfer and accounting changes to revert.

No compilation, deployment, or Ganache tests have been executed for this report. These are planned checks, not passing test results.
