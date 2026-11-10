# Smart Contract Development Assignment — Contracts 01–04

## Student and environment

- **Student:** Truong Duc Quoc Huy
- **Roll No.:** 9
- **Email:** johnnypors2@gmail.com
- **Compiler:** Solidity 0.8.34
- **EVM target:** Paris
- **Network:** Ganache, chain ID 1337

---

## Contract 01 — Storage

**File:** `contracts/01_Storage.sol`  
**Level:** Basic

### Purpose

`Storage` stores one private `uint256` value. The constructor initializes it, `get()` reads it, and `set()` changes it. The `ValueSet` event records the caller and new value for both initialization and later updates.

### Implementation

- Constructor argument: `_init`
- Read function: `get()`, `view`
- Write function: `set(uint256)`
- Event: `ValueSet(address indexed who, uint256 newValue)`
- No access control: any account can call `set()`.

### Deployment and test

- Constructor value: `42`
- Contract: `Storage`
- Address: `0x1A15fB7944D72513A519818F5877Ae04deb4F486`
- Deployment block: `8`
- Gas used: `170,746`
- Deployment status: successful
- Deployment event: `ValueSet(deployer, 42)`

The deployment event data decoded to value `42`, confirming that the constructor initialized the state correctly. The available Ganache screenshots document setting and reading additional values.

### Security and design notes

This is intentionally simple. Since `set()` is public, the stored value is mutable by every account. The contract has no payable functions, external calls, loops, or upgradeability mechanism.

---

## Contract 02 — Greeting

**File:** `contracts/02_Greeting.sol`  
**Level:** Basic

### Purpose

`Greeting` stores a string greeting. The deployer becomes the owner, only the owner can change or reset the greeting, and anyone can read it through `greet()`.

### Implementation

- Constructor argument: `_g`
- Owner getter: `owner()`
- Owner-only functions: `setGreeting()` and `resetGreeting()`
- Read function: `greet()`, `view`
- Default reset value: `Hello, World!`
- Event: `GreetingChanged(address changer, string newGreeting)`

The owner checks use `require()` with the message:

```text
Greeting: caller is not the owner
```

### Deployment and test

- Constructor value: `GM Ganache`
- Contract: `Greeting`
- Address: `0x6c316b05b4691243e63086090F56f50C19Ca17E2`
- Deployment block: `10`
- Gas used: `480,395`
- Deployment status: successful
- Initial event: `GreetingChanged(deployer, "GM Ganache")`

The event data decoded to `GM Ganache`, confirming correct constructor initialization. The reset and unauthorized-account behavior are documented in the Ganache screenshots.

### Security and design notes

The owner is fixed to the deployer because this contract has no ownership-transfer function. There are no external calls or payable functions. The dynamic string can be arbitrarily large, so gas usage grows with the greeting length.

---

## Contract 03 — Counter with Events

**File:** `contracts/03_Counter.sol`  
**Level:** Basic

### Purpose

`Counter` maintains a public counter within the inclusive range `[0, 100]`. Boundary checks prevent incrementing above `MAX` or decrementing below zero.

### Implementation

- `count`: public counter
- `MAX`: public constant equal to `100`
- `increment()`: requires `count < MAX`, otherwise reverts with `Max limit reached`
- `decrement()`: requires `count > 0`, otherwise reverts with `Count is zero`
- `reset()`: explicitly sets the counter to zero
- Events:
  - `Incremented(address indexed who, uint256 newCount)`
  - `Decremented(address indexed who, uint256 newCount)`
  - `Reset(address indexed who)`

### Deployment and test

- Contract: `Counter`
- Address: `0x1d87DACBB2650B4d88B176D2c7ca68EC85E763C7`
- Deployment block: `18`
- Gas used: `361,636`
- Deployment status: successful

The counter was incremented and boundary behavior was tested through the contract interface. At `100`, another increment reverts with `Max limit reached`; at `0`, decrement reverts with `Count is zero`. Successful changes emit the corresponding event with the post-operation count, and reset emits `Reset`.

### Security and design notes

The boundary requirements prevent arithmetic underflow and overflow. `reset()` is intentionally public because the specification requires an explicit reset operation without owner access control. There are no ETH transfers, external calls, dynamic arrays, or upgradeability features.

---

## Contract 04 — Ownable and ProtectedVault

**File:** `contracts/04_Ownable.sol`  
**Level:** Medium

### Purpose

This contract demonstrates reusable ownership through inheritance. `Ownable` contains the owner state, ownership event, owner check, and ownership transfer. `ProtectedVault` inherits those features and adds ETH deposits and owner-only withdrawals.

### Ownable implementation

- Constructor sets `owner = msg.sender`.
- `onlyOwner` requires:

```text
Not the owner
```

- `transferOwnership(address newOwner)` rejects the zero address with `Invalid owner address`.
- Ownership changes emit `OwnershipTransferred(previousOwner, newOwner)`.

### ProtectedVault implementation

- `deposit()` is `payable`, so callers can send ETH using `msg.value`.
- Anyone may deposit.
- `withdraw(address to, uint256 amt)` is protected by `onlyOwner`.
- Withdrawal rejects the zero recipient.
- Withdrawal checks both the actual contract balance and the internal `treasure` amount before sending.
- ETH is sent using:

```solidity
(bool success, ) = payable(to).call{value: amt}("");
```

- `contractBalance()` returns the contract's native ETH balance.

### Why modifiers reduce code duplication

The `onlyOwner` modifier places the owner authorization check in one reusable location. Without a modifier, the same `require(msg.sender == owner, "Not the owner")` code would have to be copied into `transferOwnership`, `withdraw`, and every future owner-only function. A modifier keeps the rule consistent, makes functions easier to read, and allows the authorization logic to be updated once instead of in multiple locations.

### Deployment and test record

After restarting Ganache, a fresh vault deployment was made:

- Network: Ganache, chain ID `1337`
- Contract: `ProtectedVault`
- Fresh deployment address: `0x8cBb5E2c40ca9898702e5FB6E27a235cA4C7c32a`
- Deployment block: `2`
- Gas used: `595,043`
- Initial owner: Account 1, `0x1b97b0791b9972b35539595164f87cfc6ac16c6a`

The following ownership checks passed:

1. Account 1 deployed the vault and was returned by `owner()`.
2. `transferOwnership(Account2)` succeeded.
3. `OwnershipTransferred` recorded Account 1 as the previous owner and Account 2 as the new owner.
4. The final `owner()` value was Account 2.
5. An unauthorized withdrawal attempt reverted with the owner restriction.

The recorded test flow also included a 1 ETH deposit attempt from Account 1 and an attempted withdrawal by Account 2. The available Remix/Ganache tooling reported the deposit transaction as successful, but subsequent reads for the tested instance showed zero contract balance. Account switching also failed to reliably submit a transaction from Account 2; therefore, a successful post-transfer Account 2 withdrawal and verified +1 ETH balance increase cannot be claimed as completed evidence in this run.

### Required test procedure for a clean final verification

1. Deploy `ProtectedVault` from Account 1.
2. Confirm `owner() == Account1`.
3. Call `deposit()` from Account 1 with exactly `1 ETH`.
4. Confirm `contractBalance() == 1 ETH`.
5. From Account 2, call `withdraw(Account2, 1 ETH)` and confirm it reverts with `Not the owner`.
6. From Account 1, call `transferOwnership(Account2)`.
7. Confirm `owner() == Account2` and inspect `OwnershipTransferred`.
8. From Account 2, call `withdraw(Account2, 1 ETH)`.
9. Confirm the vault balance is zero and Account 2 increased by approximately 1 ETH minus transaction gas.
10. Compare Account 1's balance after accounting for deployment, deposit, and ownership-transfer gas.

### Security and design notes

The withdrawal follows checks-effects-interactions: validation occurs first, `treasure` is reduced before the external ETH call, and a failed call reverts the complete transaction. The actual contract balance check prevents withdrawal of more ETH than the vault holds. The low-level call introduces an external interaction, but the state update-before-call pattern and revert-on-failure provide the intended protection.

---

## Overall conclusion

Contracts 01–03 were implemented, compiled, deployed, and tested on Ganache with their required state transitions, boundary checks, and events. Contract 04 was implemented with inheritance, a reusable `onlyOwner` modifier, payable deposits, ownership transfer, and guarded withdrawals. Its deployment, owner initialization, ownership transfer, and unauthorized-access rejection were verified; the final Account 2 withdrawal/balance-increase step requires one clean rerun with reliable account selection and a confirmed 1 ETH deposit balance.
