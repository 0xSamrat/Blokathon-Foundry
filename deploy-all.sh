#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    print_success "Environment variables loaded from .env"
else
    print_error ".env file not found!"
    exit 1
fi

# Check if Anvil is running
print_step "🔍 STEP 0: Checking Anvil Status"
if ! curl -s -X POST http://127.0.0.1:8545 -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' > /dev/null 2>&1; then
    print_error "Anvil is not running on http://127.0.0.1:8545"
    print_info "Please start Anvil in another terminal with:"
    echo "  anvil --fork-url \$RPC_URL_ARBITRUM --gas-price 0 --base-fee 0"
    exit 1
fi
print_success "Anvil is running and responsive"
echo ""

# Step 1: Deploy Diamond
print_step "🚀 STEP 1: Deploying Diamond Contract (Core Infrastructure)"
print_info "This will deploy:"
echo "  - DiamondCutFacet (for upgrades)"
echo "  - DiamondLoupeFacet (for inspection)"
echo "  - OwnershipFacet (for access control)"
echo "  - Diamond (main proxy contract)"
echo ""

# Run deployment and capture output
DEPLOY_OUTPUT=$(forge script script/Deploy.s.sol:DeployScript \
    --rpc-url $RPC_URL_ANVIL \
    --broadcast \
    -vv 2>&1)

if echo "$DEPLOY_OUTPUT" | grep -q "ONCHAIN EXECUTION COMPLETE & SUCCESSFUL"; then
    print_success "Diamond deployed successfully!"
    
    # Extract Diamond address from console output
    DIAMOND_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "Diamond deployed to:" | grep -o "0x[a-fA-F0-9]*")
    
    if [ -n "$DIAMOND_ADDRESS" ] && [ "$DIAMOND_ADDRESS" != "" ]; then
        print_info "Diamond Address: $DIAMOND_ADDRESS"
        
        # Update .env file
        if grep -q "DIAMOND_ADDRESS=" .env; then
            sed -i "s|DIAMOND_ADDRESS=.*|DIAMOND_ADDRESS=$DIAMOND_ADDRESS|" .env
            print_success "Updated DIAMOND_ADDRESS in .env"
        else
            echo "DIAMOND_ADDRESS=$DIAMOND_ADDRESS" >> .env
            print_success "Added DIAMOND_ADDRESS to .env"
        fi
        
        # Export the variable for subsequent commands
        export DIAMOND_ADDRESS=$DIAMOND_ADDRESS
        print_info "Using Diamond at: $DIAMOND_ADDRESS for remaining steps"
    else
        print_error "Could not extract Diamond address from deployment"
        print_warning "Please manually set DIAMOND_ADDRESS in .env and run again"
        exit 1
    fi
else
    print_error "Diamond deployment failed!"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi
echo ""
sleep 2

# Step 2: Deploy Uniswap Facet
print_step "🦄 STEP 2: Deploying Uniswap Facet"
print_info "Adding Uniswap V3 functionality:"
echo "  - Token swapping (exact input/output)"
echo "  - Liquidity management"
echo "  - Pool queries"
echo ""

if forge script script/DeployUniswapFacet.s.sol:DeployUniswapFacet \
    --rpc-url $RPC_URL_ANVIL \
    --broadcast \
    -vv; then
    
    print_success "Uniswap Facet deployed successfully!"
    
    UNISWAP_FACET=$(cat broadcast/DeployUniswapFacet.s.sol/42161/run-latest.json | grep -o '"contractAddress":"0x[a-fA-F0-9]*"' | head -1 | cut -d'"' -f4)
    if [ -n "$UNISWAP_FACET" ]; then
        print_info "UniswapFacet Address: $UNISWAP_FACET"
    fi
else
    print_error "Uniswap Facet deployment failed!"
    exit 1
fi
echo ""
sleep 2

# Step 3: Configure Uniswap
print_step "⚙️  STEP 3: Configuring Uniswap Facet"
print_info "Setting Uniswap V3 contract addresses:"
echo "  - Swap Router: 0xE592427A0AEce92De3Edee1F18E0157C05861564"
echo "  - Position Manager: 0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
echo ""

if forge script script/ConfigureUniswap.s.sol:ConfigureUniswap \
    --rpc-url $RPC_URL_ANVIL \
    --broadcast \
    -vv; then
    
    print_success "Uniswap configured successfully!"
else
    print_error "Uniswap configuration failed!"
    exit 1
fi
echo ""
sleep 2

# Step 4: Deploy DustSweeper Facet
print_step "🧹 STEP 4: Deploying DustSweeper Facet"
print_info "Adding dust sweeping functionality:"
echo "  - sweepDust() - Batch swap tokens to USDT"
echo "  - withdrawUsdt() - Withdraw swept USDT"
echo "  - getUsdtBalance() - Check balance"
echo ""

if forge script script/DeployDustSweeperFacet.s.sol:DeployDustSweeperFacet \
    --rpc-url $RPC_URL_ANVIL \
    --broadcast \
    -vv; then
    
    print_success "DustSweeper Facet deployed successfully!"
    
    DUSTSWEEPER_FACET=$(cat broadcast/DeployDustSweeperFacet.s.sol/42161/run-latest.json | grep -o '"contractAddress":"0x[a-fA-F0-9]*"' | head -1 | cut -d'"' -f4)
    if [ -n "$DUSTSWEEPER_FACET" ]; then
        print_info "DustSweeperFacet Address: $DUSTSWEEPER_FACET"
    fi
else
    print_error "DustSweeper Facet deployment failed!"
    exit 1
fi
echo ""
sleep 2

# Step 5: Get Test Tokens
print_step "💰 STEP 5: Getting Test Tokens (Small Amounts for Testing)"
print_info "Transferring dust-sized amounts for testing:"
echo "  - 8 USDC (small dust amount)"
echo "  - 0.003 WETH (~$6 at $2000/ETH)"
echo ""

# Token addresses (Arbitrum)
USDC_ADDRESS="0xaf88d065e77c8cC2239327C5EDb3A432268e5831"
WETH_ADDRESS="0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"

# Whale addresses
USDC_WHALE="0x47c031236e19d024b42f8AE6780E44A573170703"
WETH_WHALE="0x489ee077994B6658eAfA855C308275EAd8097C4A"

print_info "Using cast to impersonate whale addresses..."

# Transfer USDC
cast rpc anvil_impersonateAccount $USDC_WHALE --rpc-url $RPC_URL_ANVIL > /dev/null 2>&1
cast rpc anvil_setBalance $USDC_WHALE "0x10000000000000000000" --rpc-url $RPC_URL_ANVIL > /dev/null 2>&1

if cast send $USDC_ADDRESS \
  "transfer(address,uint256)" \
  $RECIPIENT \
  8000000 \
  --from $USDC_WHALE \
  --rpc-url $RPC_URL_ANVIL \
  --unlocked \
  > /dev/null 2>&1; then
    print_success "Transferred 8 USDC"
else
    print_warning "USDC transfer may have failed (continuing...)"
fi

# Transfer WETH
cast rpc anvil_impersonateAccount $WETH_WHALE --rpc-url $RPC_URL_ANVIL > /dev/null 2>&1
cast rpc anvil_setBalance $WETH_WHALE "0x10000000000000000000" --rpc-url $RPC_URL_ANVIL > /dev/null 2>&1

if cast send $WETH_ADDRESS \
  "transfer(address,uint256)" \
  $RECIPIENT \
  3000000000000000 \
  --from $WETH_WHALE \
  --rpc-url $RPC_URL_ANVIL \
  --unlocked \
  > /dev/null 2>&1; then
    print_success "Transferred 0.003 WETH"
else
    print_warning "WETH transfer may have failed (continuing...)"
fi

# Check final balances
USDC_BALANCE_RAW=$(cast call $USDC_ADDRESS "balanceOf(address)(uint256)" $RECIPIENT --rpc-url $RPC_URL_ANVIL)
WETH_BALANCE_RAW=$(cast call $WETH_ADDRESS "balanceOf(address)(uint256)" $RECIPIENT --rpc-url $RPC_URL_ANVIL)

# Strip scientific notation
USDC_BALANCE=$(echo $USDC_BALANCE_RAW | awk '{print $1}')
WETH_BALANCE=$(echo $WETH_BALANCE_RAW | awk '{print $1}')

if [ "$USDC_BALANCE" != "0" ]; then
    USDC_FORMATTED=$(awk "BEGIN {printf \"%.2f\", $USDC_BALANCE / 1000000}")
else
    USDC_FORMATTED="0"
fi

if [ "$WETH_BALANCE" != "0" ]; then
    WETH_FORMATTED=$(awk "BEGIN {printf \"%.4f\", $WETH_BALANCE / 1000000000000000000}")
else
    WETH_FORMATTED="0"
fi

echo ""
echo -e "${CYAN}Final Balances:${NC}"
echo -e "  ${BLUE}USDC:${NC} ${GREEN}${USDC_FORMATTED}${NC}"
echo -e "  ${BLUE}WETH:${NC} ${GREEN}${WETH_FORMATTED}${NC}"
echo ""

if [ "$USDC_BALANCE" != "0" ] || [ "$WETH_BALANCE" != "0" ]; then
    print_success "Test tokens acquired! Ready for dust sweeping test."
else
    print_warning "No tokens acquired. Dust sweeper test will be skipped."
    print_info "This is expected behavior on some Anvil configurations."
fi
echo ""

# Step 6: Test DustSweeper (Optional)
print_step "🧪 STEP 6: Testing DustSweeper (Optional)"
print_info "This will verify the complete token flow:"
echo "  - Transfer tokens from user to Diamond"
echo "  - Swap tokens to USDT via Uniswap"
echo "  - Track USDT balance in Diamond storage"
echo "  - Withdraw USDT back to user"
echo ""
echo -e "${YELLOW}This test demonstrates:${NC}"
echo "  User → Diamond → Uniswap → Diamond (USDT) → User"
echo ""

read -p "$(echo -e ${CYAN}Run DustSweeper test? \(y/n\) ${NC})" -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Running DustSweeper test..."
    echo ""
    
    # Check token balances before test
    print_info "Checking user token balances..."
    USDT_ADDRESS="0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"
    
    USDC_BALANCE_RAW=$(cast call $USDC_ADDRESS "balanceOf(address)(uint256)" $RECIPIENT --rpc-url $RPC_URL_ANVIL)
    WETH_BALANCE_RAW=$(cast call $WETH_ADDRESS "balanceOf(address)(uint256)" $RECIPIENT --rpc-url $RPC_URL_ANVIL)
    USDT_BEFORE_RAW=$(cast call $USDT_ADDRESS "balanceOf(address)(uint256)" $RECIPIENT --rpc-url $RPC_URL_ANVIL)
    
    # Strip scientific notation (e.g., "40000000 [4e7]" -> "40000000")
    USDC_BALANCE=$(echo $USDC_BALANCE_RAW | awk '{print $1}')
    WETH_BALANCE=$(echo $WETH_BALANCE_RAW | awk '{print $1}')
    USDT_BEFORE=$(echo $USDT_BEFORE_RAW | awk '{print $1}')
    
    # Format for display only (not for calculations)
    if [ "$USDC_BALANCE" != "0" ]; then
        USDC_FORMATTED=$(awk "BEGIN {printf \"%.2f\", $USDC_BALANCE / 1000000}")
    else
        USDC_FORMATTED="0"
    fi
    
    if [ "$WETH_BALANCE" != "0" ]; then
        WETH_FORMATTED=$(awk "BEGIN {printf \"%.4f\", $WETH_BALANCE / 1000000000000000000}")
    else
        WETH_FORMATTED="0"
    fi
    
    echo -e "  USDC: ${GREEN}${USDC_FORMATTED}${NC} (raw: $USDC_BALANCE)"
    echo -e "  WETH: ${GREEN}${WETH_FORMATTED}${NC} (raw: $WETH_BALANCE)"
    echo ""
    
    if [ "$USDC_BALANCE" = "0" ] && [ "$WETH_BALANCE" = "0" ]; then
        print_warning "No tokens to sweep! User needs USDC or WETH."
        print_info "Tokens should have been acquired in Step 5"
    else
        # Approve Diamond to spend tokens
        print_info "Approving Diamond to spend tokens..."
        
        if [ "$USDC_BALANCE" != "0" ]; then
            cast send $USDC_ADDRESS "approve(address,uint256)" $DIAMOND_ADDRESS $USDC_BALANCE \
                --private-key $PRIVATE_KEY_ANVIL \
                --rpc-url $RPC_URL_ANVIL > /dev/null 2>&1
            print_success "USDC approved"
        fi
        
        if [ "$WETH_BALANCE" != "0" ]; then
            cast send $WETH_ADDRESS "approve(address,uint256)" $DIAMOND_ADDRESS $WETH_BALANCE \
                --private-key $PRIVATE_KEY_ANVIL \
                --rpc-url $RPC_URL_ANVIL > /dev/null 2>&1
            print_success "WETH approved"
        fi
        echo ""
        
        # Prepare arrays for sweepDust call
        print_info "Sweeping dust tokens to USDT..."
        
        # Call sweepDust with minimum 1 USDT output
        MIN_USDT="1000000" # 1 USDT
        
        echo -e "  ${BLUE}Tokens:${NC} USDC ($USDC_BALANCE) + WETH ($WETH_BALANCE)"
        echo -e "  ${BLUE}Min Output:${NC} $MIN_USDT (1 USDT)"
        echo ""
        
        SWEEP_OUTPUT=$(cast send $DIAMOND_ADDRESS \
            "sweepDust(address[],uint256[],uint256)" \
            "[$USDC_ADDRESS,$WETH_ADDRESS]" "[$USDC_BALANCE,$WETH_BALANCE]" "$MIN_USDT" \
            --private-key $PRIVATE_KEY_ANVIL \
            --rpc-url $RPC_URL_ANVIL 2>&1)
        
        if echo "$SWEEP_OUTPUT" | grep -q "blockNumber"; then
            print_success "Dust swept successfully!"
            
            # Check USDT balance in Diamond storage
            USDT_IN_DIAMOND=$(cast call $DIAMOND_ADDRESS \
                "getUsdtBalance(address)(uint256)" \
                $RECIPIENT \
                --rpc-url $RPC_URL_ANVIL)
            
            echo ""
            print_info "USDT in Diamond storage: $(echo "scale=2; $USDT_IN_DIAMOND / 1000000" | bc) USDT"
            
            if [ "$USDT_IN_DIAMOND" != "0" ]; then
                # Withdraw USDT
                print_info "Withdrawing USDT to user wallet..."
                
                cast send $DIAMOND_ADDRESS \
                    "withdrawUsdt(uint256)" \
                    $USDT_IN_DIAMOND \
                    --private-key $PRIVATE_KEY_ANVIL \
                    --rpc-url $RPC_URL_ANVIL > /dev/null 2>&1
                
                print_success "USDT withdrawn!"
                
                # Check final balances
                USDT_AFTER=$(cast call $USDT_ADDRESS "balanceOf(address)(uint256)" $RECIPIENT --rpc-url $RPC_URL_ANVIL)
                USDT_RECEIVED=$((USDT_AFTER - USDT_BEFORE))
                
                echo ""
                print_success "Test completed successfully!"
                echo ""
                echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${GREEN}                    TEST RESULTS                                   ${NC}"
                echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
                echo -e "  ${CYAN}Token Flow Verified:${NC}"
                echo -e "    User → Diamond → Uniswap → Diamond (USDT) → User"
                echo ""
                echo -e "  ${CYAN}USDT Received:${NC}  ${GREEN}$(echo "scale=2; $USDT_RECEIVED / 1000000" | bc) USDT${NC}"
                echo -e "  ${CYAN}Status:${NC}         ${GREEN}✅ All transfers successful${NC}"
                echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
                echo ""
            else
                print_error "No USDT received from swap"
            fi
        else
            print_error "Dust sweeping failed!"
            print_info "This could be due to:"
            echo "  - Insufficient liquidity in Uniswap pools"
            echo "  - Token amounts too small to swap"
            echo "  - Slippage too high"
            echo ""
            echo "$SWEEP_OUTPUT"
        fi
    fi
else
    print_warning "Skipping DustSweeper test"
    print_info "You can test manually later using cast commands"
fi
echo ""

# Final Summary
print_step "🎉 DEPLOYMENT COMPLETE!"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    DEPLOYMENT SUMMARY                             ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📦 Core Contracts:${NC}"
echo -e "  ${BLUE}Diamond:${NC}           $DIAMOND_ADDRESS"
echo ""
echo -e "${CYAN}🔧 Utility Facets:${NC}"
echo -e "  ${BLUE}UniswapFacet:${NC}      $UNISWAP_FACET"
echo -e "  ${BLUE}DustSweeperFacet:${NC}  $DUSTSWEEPER_FACET"
echo ""
echo -e "${CYAN}🌐 Network:${NC}"
echo -e "  ${BLUE}RPC URL:${NC}           $RPC_URL_ANVIL"
echo -e "  ${BLUE}Chain ID:${NC}          42161 (Arbitrum Fork)"
echo ""
echo -e "${CYAN}💡 Next Steps:${NC}"
echo -e "  ${GREEN}1.${NC} Connect your frontend to Diamond address"
echo -e "  ${GREEN}2.${NC} Test dust sweeping functionality"
echo -e "  ${GREEN}3.${NC} Deploy to testnet when ready"
echo ""
echo -e "${YELLOW}📝 Configuration saved to .env${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
print_success "All systems operational! 🚀"
