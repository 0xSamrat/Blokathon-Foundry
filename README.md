# 🧹 Dust Sweeper - Smart Token Consolidation Platform

**Convert your scattered small token balances into USDT with one click**

A modular DeFi application built using the Diamond Proxy pattern (EIP-2535) that helps users consolidate "dust" tokens - small, leftover token balances that are too small to swap individually but add up to meaningful value when combined.

## 🎯 The Problem

### What is "Dust"?

After using various DeFi protocols, users often end up with:
- Small amounts of tokens left after swaps (slippage, rounding)
- Test tokens from protocol interactions
- Airdrop tokens with minimal value
- Leftover tokens from closed positions

**The Issue:**
- Each token requires a separate transaction to swap
- Gas fees often exceed the value of individual small balances
- Manual swapping is time-consuming and inefficient
- These small amounts remain unused, representing locked value

**Example Scenario:**
```
You have:
- 0.8 USDC (worth $0.80)
- 0.003 WETH (worth $10)
- 2.5 DAI (worth $2.50)
- 0.1 LINK (worth $1.80)

Total value: ~$15.10
Problem: 4 separate transactions + 4x gas fees to consolidate
```

## ✨ The Solution: Dust Sweeper

**One-click token consolidation** that:
1. ✅ Accepts multiple tokens in a single transaction
2. ✅ Swaps all tokens to USDT via Uniswap V3 automatically
3. ✅ Stores consolidated USDT in your secure Diamond vault
4. ✅ Allows withdrawal whenever you want
5. ✅ Saves gas fees by batching operations

## 🔄 User Flow

### Step 1: Approve & Sweep
```
User → Diamond Contract
├─ Approves tokens (one-time setup)
└─ Calls sweepDust([USDC, WETH, DAI], [amounts], minUsdtOut)
```

### Step 2: Automatic Conversion
```
Diamond → Uniswap V3
├─ Swaps USDC → USDT
├─ Swaps WETH → USDT  
└─ Swaps DAI → USDT
```

### Step 3: Secure Storage
```
Diamond Contract
└─ Stores total USDT in user's balance
└─ User can check balance anytime
```

### Step 4: Withdraw
```
User calls withdrawUsdt(amount)
└─ Diamond transfers USDT to user's wallet
```

## 🏗️ Architecture

Built using **EIP-2535 Diamond Standard** for:
- **Modularity**: Swap logic and storage are separate, upgradeable facets
- **Gas Efficiency**: Shared storage, optimized batch operations
- **Upgradeability**: Add new DEXs or features without redeploying
- **Unlimited Size**: Bypass 24KB contract limit for complex DeFi logic

### Key Components

1. **Diamond Proxy** (`0x409488F6e4bcE418F9E90464863c3Caa34D6f5FE`)
   - Main entry point for all user interactions
   - Routes calls to appropriate facets via delegatecall

2. **UniswapFacet** (`0xA32e26B92C7B106D59f405B1Cb7Fe6beDf5E250b`)
   - Handles all Uniswap V3 swap operations
   - Uses 0.05% fee tier pools for optimal liquidity

3. **DustSweeperFacet** (`0x865B84d6bA604D24a43eADD464f6f75101965D06`)
   - Orchestrates token consolidation
   - Manages user balances in Diamond storage
   - Handles deposits and withdrawals

### Deployed on Arbitrum One

**Why Arbitrum?**
- ⚡ Low gas fees (< $0.50 per transaction)
- 🌊 Deep Uniswap V3 liquidity
- 🚀 Fast transaction finality (~2 seconds)
- 🔗 Ethereum security with L2 efficiency

---

## 💼 Use Cases

### Who Benefits?

1. **Active DeFi Traders**
   - Consolidate leftover tokens after multiple swaps
   - Clean up wallet with one transaction

2. **Yield Farmers**
   - Combine small reward tokens from multiple protocols
   - Convert farming dust into stable USDT

3. **Airdrop Hunters**
   - Turn test tokens and small airdrops into usable value
   - Batch process multiple low-value tokens

4. **Portfolio Managers**
   - Periodic cleanup of small balances
   - Maintain clean, organized token holdings

### Real Value Example

```
Before Dust Sweeper:
├─ Swap USDC: $0.80 - $0.40 gas = $0.40 profit
├─ Swap WETH: $10.00 - $0.40 gas = $9.60 profit  
├─ Swap DAI: $2.50 - $0.40 gas = $2.10 profit
└─ Swap LINK: $1.80 - $0.40 gas = $1.40 profit
Total: $13.50 (paid $1.60 in gas)

After Dust Sweeper:
└─ Sweep All: $15.10 - $0.50 gas = $14.60 profit
Saved: $1.10 + time + hassle
```

---

## 🎨 Features

### ✅ Currently Implemented

- **Batch Token Swapping**: Consolidate multiple tokens in one transaction
- **Uniswap V3 Integration**: Access deep liquidity on Arbitrum
- **Secure Storage**: USDT stored safely in Diamond contract
- **Flexible Withdrawals**: Withdraw any amount at any time
- **Gas Optimized**: Efficient batch operations save costs
- **User Balance Tracking**: Check your USDT balance anytime

### 🔮 Future Enhancements

- **Multi-DEX Support**: Add SushiSwap, Curve for better routing
- **Auto-Compound**: Automatically reinvest USDT into yield strategies
- **Cross-Chain**: Support dust sweeping across multiple networks
- **NFT Dust**: Handle low-value NFTs and convert to tokens
- **Scheduled Sweeps**: Set automatic periodic consolidation
- **Gas Token Optimization**: Accept native ETH/ARB for gas-free UX

---

## 🔧 Technical Details

### Smart Contract Architecture

```
User Wallet
    ↓
Diamond Proxy (0x409488...5FE)
    ├─ DiamondCutFacet (upgrade management)
    ├─ DiamondLoupeFacet (introspection)
    ├─ OwnershipFacet (access control)
    ├─ UniswapFacet (DEX integration)
    └─ DustSweeperFacet (core logic)
        ↓
Uniswap V3 Router
    ↓
Token Pools (USDC/USDT, WETH/USDT, etc.)
```

### Key Functions

**DustSweeperFacet:**
```solidity
// Consolidate multiple tokens to USDT
function sweepDust(
    address[] tokens,
    uint256[] amounts,
    uint256 minUsdtOut
) external returns (uint256 totalUsdt)

// Withdraw USDT from Diamond
function withdrawUsdt(uint256 amount) external

// Check your USDT balance
function getUsdtBalance(address user) external view returns (uint256)
```

### Security Features

- ✅ **OpenZeppelin SafeERC20**: Prevents token transfer vulnerabilities
- ✅ **Minimum Output Protection**: Slippage control via `minUsdtOut`
- ✅ **Isolated Storage**: Namespaced storage prevents collisions
- ✅ **Access Control**: Only token owner can withdraw their balance
- ✅ **Reentrancy Safe**: Checks-effects-interactions pattern

---

## 📚 Understanding Diamond Proxy (EIP-2535)

The **Diamond Proxy** pattern allows a single contract to use multiple implementation contracts (facets) through delegatecall. This enables:

- **Modularity**: Add, replace, or remove functionality without redeploying everything
- **Unlimited Contract Size**: Bypass the 24KB contract size limit
- **Shared State**: All facets share the same storage
- **Upgradeability**: Upgrade parts of your system independently

### Why Diamond for Dust Sweeper?

1. **Future-Proof**: Easily add support for new DEXs without redeploying
2. **Gas Efficient**: Shared storage reduces redundant state variables
3. **Composable**: Can add lending, staking, or other DeFi features later
4. **Transparent Upgrades**: Users interact with same address forever

**Resources:**
- [EIP-2535 Specification](https://eips.ethereum.org/EIPS/eip-2535)
- [Diamond Standard Documentation](https://eip2535diamonds.substack.com/)

---

## 🚀 Quick Start Guide

### For Users (Interacting with Deployed Contracts)

**Prerequisites:**
- MetaMask or any Web3 wallet
- Some ARB for gas fees on Arbitrum
- Dust tokens you want to consolidate

**Step-by-Step:**

1. **Connect to Arbitrum One Network**
   - Network: Arbitrum One
   - RPC: https://arb1.arbitrum.io/rpc
   - Chain ID: 42161

2. **Approve Tokens**
   ```javascript
   // Approve Diamond to spend your tokens
   // Call approve() on each token contract
   tokenContract.approve(
     "0x409488F6e4bcE418F9E90464863c3Caa34D6f5FE", // Diamond address
     amount
   )
   ```

3. **Sweep Your Dust**
   ```javascript
   // Call sweepDust on Diamond contract
   diamond.sweepDust(
     [tokenAddress1, tokenAddress2, ...], // Token addresses
     [amount1, amount2, ...],              // Amounts to sweep
     minUsdtOut                            // Minimum USDT you expect
   )
   ```

4. **Check Your Balance**
   ```javascript
   diamond.getUsdtBalance(yourAddress)
   ```

5. **Withdraw USDT**
   ```javascript
   diamond.withdrawUsdt(amount)
   ```

---

## 🛠️ For Developers

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Basic understanding of Solidity and Diamond pattern
- Git installed

### 1. Clone the Repository

```bash
git clone https://github.com/BLOKCapital/Blokathon-Foundry.git
cd Blokathon-Foundry

# Install dependencies
forge install
```

### 2. Set Up Environment Variables

```bash
# Copy the example environment file
cp .envExample .env

# Edit .env with your credentials
nano .env  # or use your preferred editor
```

**`.env` file structure:**
```bash
PRIVATE_KEY_ANVIL=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_URL_ANVIL=http://127.0.0.1:8545

# For deploying to real networks
PRIVATE_KEY=your_private_key_here
RPC_URL_ARBITRUM=https://arb1.arbitrum.io/rpc

# Etherscan API keys for verification
API_KEY_ARBISCAN=your_arbiscan_api_key
```

### 3. Test Locally with Anvil

```bash
# Terminal 1: Start local Arbitrum fork
anvil --fork-url https://arb1.arbitrum.io/rpc

# Terminal 2: Run deployment script
source .env
./deploy-all.sh
```

This will:
- ✅ Deploy Diamond proxy
- ✅ Deploy and configure UniswapFacet
- ✅ Deploy and configure DustSweeperFacet
- ✅ Get test tokens (USDC, WETH)
- ✅ Test complete sweep flow
- ✅ Verify withdrawal works

---

## 🧪 Testing & Development

### Build Contracts

```bash
forge build
```

### Run Tests

```bash
forge test

# Run with verbosity for detailed output
forge test -vvv

# Test specific function
forge test --match-test testSweepDust
```

### Format Code

```bash
forge fmt
```

### Clean Build Artifacts

```bash
forge clean
```

---

## 🌐 Deployment Guide

### Deploy to Arbitrum Mainnet

```bash
source .env

# Run complete deployment pipeline
./deploy-all.sh
```

The script will:
1. Deploy Diamond proxy contract
2. Deploy UniswapFacet and configure Uniswap V3 integration
3. Deploy DustSweeperFacet with sweep/withdraw functionality
4. Optionally test the complete flow with real tokens

### Manual Deployment Steps

If you prefer step-by-step deployment:

```bash
# 1. Deploy Diamond
forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL_ARBITRUM \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify

# 2. Deploy Uniswap Facet
forge script script/DeployUniswapFacet.s.sol \
  --rpc-url $RPC_URL_ARBITRUM \
  --private-key $PRIVATE_KEY \
  --broadcast

# 3. Configure Uniswap
forge script script/ConfigureUniswap.s.sol \
  --rpc-url $RPC_URL_ARBITRUM \
  --private-key $PRIVATE_KEY \
  --broadcast

# 4. Deploy Dust Sweeper Facet
forge script script/DeployDustSweeperFacet.s.sol \
  --rpc-url $RPC_URL_ARBITRUM \
  --private-key $PRIVATE_KEY \
  --broadcast
```

### Upgrade Existing Facet

```bash
forge script script/UpdateDustSweeperFacet.s.sol \
  --rpc-url $RPC_URL_ARBITRUM \
  --private-key $PRIVATE_KEY \
  --broadcast
```

---

## 📁 Repository Structure

```
Blokathon-Foundry/
├── src/
│   ├── Diamond.sol                          # Main Diamond proxy contract
│   ├── facets/
│   │   ├── Facet.sol                        # Base facet contract
│   │   ├── baseFacets/                      # Core Diamond facets
│   │   │   ├── cut/                         # DiamondCut (upgrade system)
│   │   │   ├── loupe/                       # DiamondLoupe (introspection)
│   │   │   └── ownership/                   # Ownership management
│   │   └── utilityFacets/
│   │       ├── uniswap/                     # Uniswap V3 integration
│   │       │   ├── UniswapBase.sol          # Swap logic
│   │       │   ├── UniswapFacet.sol         # Public swap interface
│   │       │   └── UniswapStorage.sol       # Router addresses
│   │       └── dustSweeper/                 # 🧹 Dust Sweeper feature
│   │           ├── DustSweeperBase.sol      # Core consolidation logic
│   │           ├── DustSweeperFacet.sol     # User-facing functions
│   │           └── DustSweeperStorage.sol   # User balance tracking
│   ├── interfaces/                          # Interface definitions
│   └── libraries/                           # Shared libraries (LibDiamond)
├── script/
│   ├── Deploy.s.sol                         # Diamond deployment
│   ├── DeployUniswapFacet.s.sol            # Uniswap facet deployment
│   ├── ConfigureUniswap.s.sol              # Set router addresses
│   ├── DeployDustSweeperFacet.s.sol        # Dust sweeper deployment
│   ├── UpdateDustSweeperFacet.s.sol        # Facet upgrade script
│   └── deploy-all.sh                        # 🚀 One-click deployment
├── test/                                    # Test files
└── README.md                                # This file
```

---

## 🧪 Using Cast for Interactions

### Query Functions

```bash
# Check your USDT balance in the Diamond
cast call 0x409488F6e4bcE418F9E90464863c3Caa34D6f5FE \
  "getUsdtBalance(address)" YOUR_ADDRESS \
  --rpc-url https://arb1.arbitrum.io/rpc

# Get all facets in the Diamond
cast call 0x409488F6e4bcE418F9E90464863c3Caa34D6f5FE \
  "facets()" \
  --rpc-url https://arb1.arbitrum.io/rpc
```

### Send Transactions

```bash
# Approve Diamond to spend USDC
cast send 0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \
  "approve(address,uint256)" \
  0x409488F6e4bcE418F9E90464863c3Caa34D6f5FE \
  1000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url https://arb1.arbitrum.io/rpc

# Sweep dust tokens
cast send 0x409488F6e4bcE418F9E90464863c3Caa34D6f5FE \
  "sweepDust(address[],uint256[],uint256)" \
  "[0xaf88d065e77c8cC2239327C5EDb3A432268e5831]" \
  "[1000000]" \
  0 \
  --private-key $PRIVATE_KEY \
  --rpc-url https://arb1.arbitrum.io/rpc

# Withdraw USDT
cast send 0x409488F6e4bcE418F9E90464863c3Caa34D6f5FE \
  "withdrawUsdt(uint256)" \
  1000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url https://arb1.arbitrum.io/rpc
```

---

## 🎓 Learning Resources

### Diamond Pattern

- **EIP-2535 Specification**: https://eips.ethereum.org/EIPS/eip-2535
- **Diamond Standard Guide**: https://eip2535diamonds.substack.com/
- **Nick Mudge's Articles**: https://dev.to/mudgen

### Development Tools

- **Foundry Book**: https://book.getfoundry.sh/
- **Solidity Documentation**: https://docs.soliditylang.org/
- **OpenZeppelin Contracts**: https://docs.openzeppelin.com/contracts/

### Uniswap V3

- **Uniswap V3 Core**: https://docs.uniswap.org/contracts/v3/overview
- **Swap Router Guide**: https://docs.uniswap.org/contracts/v3/guides/swaps/single-swaps

---

## 📊 Project Stats

- **Total Contracts**: 15+ Solidity files
- **Architecture**: EIP-2535 Diamond Standard
- **Network**: Arbitrum One (Chain ID: 42161)
- **DEX Integration**: Uniswap V3
- **Gas Optimization**: Batch operations, shared storage
- **Security**: OpenZeppelin SafeERC20, access control

### Deployment Addresses (Arbitrum One)

```
Diamond Proxy:       0x409488F6e4bcE418F9E90464863c3Caa34D6f5FE
UniswapFacet:        0xA32e26B92C7B106D59f405B1Cb7Fe6beDf5E250b
DustSweeperFacet:    0x865B84d6bA604D24a43eADD464f6f75101965D06
```

---

## 💡 Future Roadmap

### Phase 1: Multi-DEX Support (Q1 2026)
- ✅ Uniswap V3 (Current)
- ⏳ SushiSwap integration
- ⏳ Curve Finance for stablecoin swaps
- ⏳ Smart routing across DEXs for best rates

### Phase 2: Advanced Features (Q2 2026)
- ⏳ Auto-compound: Reinvest USDT into yield strategies
- ⏳ Scheduled sweeps: Automated periodic consolidation
- ⏳ Gas optimization: Gasless transactions via meta-transactions
- ⏳ Multi-token output: Convert to ETH, BTC, or other targets

### Phase 3: Cross-Chain (Q3 2026)
- ⏳ Polygon support
- ⏳ Base support
- ⏳ Avalanche support
- ⏳ Cross-chain bridge integration

### Phase 4: Advanced DeFi (Q4 2026)
- ⏳ NFT dust sweeping
- ⏳ LP token consolidation
- ⏳ Integration with lending protocols (Aave)
- ⏳ Yield aggregator integration

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Report Bugs**: Open an issue with detailed reproduction steps
2. **Suggest Features**: Share ideas for new functionality
3. **Submit PRs**: Fix bugs or add features (follow existing code style)
4. **Improve Docs**: Help make the README clearer

### Development Guidelines

- Write tests for all new features
- Use OpenZeppelin libraries when possible
- Follow Diamond storage pattern (namespaced storage)
- Document public functions with NatSpec comments
- Run `forge fmt` before committing

---

## 📄 License

MIT License - see LICENSE file for details

---

## 👥 Team

Built with ❤️ for the Blok-a-Thon Hackathon

**Focus**: Wealth Management through Smart Token Consolidation

---

## 📞 Contact & Links

- **GitHub**: https://github.com/BLOKCapital/Blokathon-Foundry
- **Documentation**: See this README
- **Issues**: https://github.com/BLOKCapital/Blokathon-Foundry/issues

---

## ⚠️ Disclaimer

This is a hackathon project. While we've implemented security best practices:

- ✅ Uses OpenZeppelin's SafeERC20
- ✅ Implements access control
- ✅ Includes slippage protection
- ✅ Follows checks-effects-interactions pattern

**Important**: 
- NOT audited by professional security firms
- Use at your own risk
- Test thoroughly before using with significant funds
- Consider this experimental software

For production use, we recommend:
1. Professional security audit
2. Gradual rollout with limited funds
3. Bug bounty program
4. Comprehensive testing on testnet

---

**Ready to clean up your token dust? Start sweeping! 🧹✨**
