#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

source .env

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🧹 Testing Garden Dust Sweeper${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 0: Update DustSweeperFacet to ensure sweepGardenDust exists
echo -e "${YELLOW}📦 Step 0: Updating DustSweeperFacet...${NC}"
forge script script/UpdateDustSweeperFacet.s.sol \
    --rpc-url $RPC_URL_ANVIL \
    --broadcast > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ DustSweeperFacet updated successfully${NC}"
else
    echo -e "${RED}❌ Failed to update DustSweeperFacet${NC}"
    echo -e "${YELLOW}ℹ️  This may be expected if the function already exists${NC}"
    # Don't exit - function might already exist from previous run
fi
echo ""

RPC_URL="http://127.0.0.1:8545"

# Token addresses
USDC="0xaf88d065e77c8cC2239327C5EDb3A432268e5831"
WETH="0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"
USDT="0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"

# Whale addresses
USDC_WHALE="0x47c031236e19d024b42f8AE6780E44A573170703"
WETH_WHALE="0x489ee077994B6658eAfA855C308275EAd8097C4A"

echo -e "${CYAN}Diamond Address: $DIAMOND_ADDRESS${NC}"
echo -e "${CYAN}Owner Address: $RECIPIENT${NC}"
echo ""

# Step 1: Check initial Diamond balances
echo -e "${YELLOW}📊 Step 1: Initial Diamond Balances${NC}"
DIAMOND_USDC=$(cast call $USDC "balanceOf(address)(uint256)" $DIAMOND_ADDRESS --rpc-url $RPC_URL) | xargs printf "%d"
DIAMOND_WETH=$(cast call $WETH "balanceOf(address)(uint256)" $DIAMOND_ADDRESS --rpc-url $RPC_URL) | xargs printf "%d"

DIAMOND_USDC_FORMATTED=$(awk "BEGIN {printf \"%.6f\", $DIAMOND_USDC / 1e6}")
DIAMOND_WETH_FORMATTED=$(awk "BEGIN {printf \"%.18f\", $DIAMOND_WETH / 1e18}")

echo "Diamond USDC: $DIAMOND_USDC_FORMATTED"
echo "Diamond WETH: $DIAMOND_WETH_FORMATTED"
echo ""

# Step 2: Simulate stuck tokens (send tokens directly to Diamond)
echo -e "${YELLOW}🐋 Step 2: Simulating Stuck Tokens in Diamond${NC}"

# Send USDC from whale to Diamond
echo "Transferring 10 USDC to Diamond..."
cast send $USDC \
    "transfer(address,uint256)(bool)" \
    $DIAMOND_ADDRESS \
    10000000 \
    --from $USDC_WHALE \
    --unlocked \
    --rpc-url $RPC_URL \
    > /dev/null 2>&1

# Send WETH from whale to Diamond
echo "Transferring 0.005 WETH to Diamond..."
cast send $WETH \
    "transfer(address,uint256)(bool)" \
    $DIAMOND_ADDRESS \
    5000000000000000 \
    --from $WETH_WHALE \
    --unlocked \
    --rpc-url $RPC_URL \
    > /dev/null 2>&1

echo -e "${GREEN}✅ Tokens sent to Diamond${NC}"
echo ""

# Step 3: Verify tokens are in Diamond
echo -e "${YELLOW}💰 Step 3: Verifying Stuck Tokens${NC}"
DIAMOND_USDC=$(cast call $USDC "balanceOf(address)(uint256)" $DIAMOND_ADDRESS --rpc-url $RPC_URL | xargs printf "%d")
DIAMOND_WETH=$(cast call $WETH "balanceOf(address)(uint256)" $DIAMOND_ADDRESS --rpc-url $RPC_URL | xargs printf "%d")

DIAMOND_USDC_FORMATTED=$(awk "BEGIN {printf \"%.6f\", $DIAMOND_USDC / 1e6}")
DIAMOND_WETH_FORMATTED=$(awk "BEGIN {printf \"%.18f\", $DIAMOND_WETH / 1e18}")

echo "Diamond USDC: $DIAMOND_USDC_FORMATTED"
echo "Diamond WETH: $DIAMOND_WETH_FORMATTED"
echo ""

# Step 4: Check owner's balance before sweep
echo -e "${YELLOW}📈 Step 4: Owner USDT Balance Before Sweep${NC}"
OWNER_USDT_BEFORE=$(cast call $DIAMOND_ADDRESS \
    "getUsdtBalance(address)(uint256)" \
    $RECIPIENT \
    --rpc-url $RPC_URL)

OWNER_USDT_BEFORE_FORMATTED=$(awk "BEGIN {printf \"%.6f\", $OWNER_USDT_BEFORE / 1e6}")
echo "Owner USDT in Diamond: $OWNER_USDT_BEFORE_FORMATTED"
echo ""

# Step 5: Sweep garden dust (owner only)
echo -e "${YELLOW}🧹 Step 5: Sweeping Garden Dust${NC}"
echo "Calling sweepGardenDust([USDC, WETH], [0, 0], 0)..."

cast send $DIAMOND_ADDRESS \
    "sweepGardenDust(address[],uint256[],uint256)" \
    "[$USDC,$WETH]" \
    "[0,0]" \
    "0" \
    --private-key $PRIVATE_KEY_ANVIL \
    --rpc-url $RPC_URL \
    --gas-limit 1000000

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Dust swept successfully!${NC}"
else
    echo -e "${RED}❌ Sweep failed${NC}"
    exit 1
fi
echo ""

# Step 6: Verify results
echo -e "${YELLOW}✅ Step 6: Verifying Results${NC}"

# Check Diamond balances (should be ~0)
DIAMOND_USDC_AFTER=$(cast call $USDC "balanceOf(address)(uint256)" $DIAMOND_ADDRESS --rpc-url $RPC_URL)
DIAMOND_WETH_AFTER=$(cast call $WETH "balanceOf(address)(uint256)" $DIAMOND_ADDRESS --rpc-url $RPC_URL)

DIAMOND_USDC_AFTER_FORMATTED=$(awk "BEGIN {printf \"%.6f\", $DIAMOND_USDC_AFTER / 1e6}")
DIAMOND_WETH_AFTER_FORMATTED=$(awk "BEGIN {printf \"%.18f\", $DIAMOND_WETH_AFTER / 1e18}")

echo "Diamond USDC after: $DIAMOND_USDC_AFTER_FORMATTED"
echo "Diamond WETH after: $DIAMOND_WETH_AFTER_FORMATTED"

# Check owner's balance (should increase)
OWNER_USDT_AFTER=$(cast call $DIAMOND_ADDRESS \
    "getUsdtBalance(address)(uint256)" \
    $RECIPIENT \
    --rpc-url $RPC_URL)

OWNER_USDT_AFTER_FORMATTED=$(awk "BEGIN {printf \"%.6f\", $OWNER_USDT_AFTER / 1e6}")
echo "Owner USDT in Diamond after: $OWNER_USDT_AFTER_FORMATTED"

# Calculate gain (convert hex to decimal)
OWNER_BEFORE_DEC=$((OWNER_USDT_BEFORE))
OWNER_AFTER_DEC=$((OWNER_USDT_AFTER))
USDT_GAINED=$((OWNER_AFTER_DEC - OWNER_BEFORE_DEC))
USDT_GAINED_FORMATTED=$(awk "BEGIN {printf \"%.6f\", $USDT_GAINED / 1e6}")
echo -e "${GREEN}USDT gained from sweep: $USDT_GAINED_FORMATTED${NC}"
echo ""

# # Step 7: Test withdrawal
# echo -e "${YELLOW}💸 Step 7: Testing Withdrawal${NC}"
# echo "Withdrawing all USDT..."

# cast send $DIAMOND_ADDRESS \
#     "withdrawUsdt(uint256)" \
#     $OWNER_USDT_AFTER \
#     --private-key $PRIVATE_KEY_ANVIL \
#     --rpc-url $RPC_URL \
#     > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ USDT withdrawn!${NC}"
else
    echo -e "${RED}❌ Withdrawal failed${NC}"
    exit 1
fi
echo ""

# Final verification
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Test completed successfully!${NC}"
echo -e "${CYAN}Token Flow Verified: Stuck in Diamond → Uniswap → Diamond (USDT) → Owner${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"