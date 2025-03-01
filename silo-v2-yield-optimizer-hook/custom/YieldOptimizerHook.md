# Yield Optimizer Hook for Silo Protocol

The Yield Optimizer Hook is a powerful extension to the Silo Protocol that automatically detects and optimizes idle tokens in users' wallets. By monitoring user interactions with Silo markets (deposits, withdrawals, borrows, and repayments), this hook identifies unused tokens that could be earning yield and provides pathways to deploy them to the most profitable opportunities.

## Key Features

- **Idle Token Detection**: Automatically identifies tokens in users' wallets that are not actively being used.
- **Yield Strategy Selection**: Analyzes available yield strategies across Silo markets and other DeFi protocols to find the best returns based on user-defined risk parameters.
- **Auto-Deployment (Optional)**: With user consent, automatically deploys idle tokens to optimal yield strategies.
- **Risk-Adjusted Returns**: Factors in user-defined risk tolerance levels to ensure allocations match their preferences.
- **Configurable Thresholds**: Adjustable minimum token amounts to ensure optimization only occurs when profitable after gas costs.

## How It Works

1. **User Interaction**: When a user interacts with a Silo market (deposit, withdraw, borrow, repay), the hook is triggered.
2. **Balance Analysis**: The hook checks if the user has enabled yield optimization and analyzes their wallet balances.
3. **Strategy Identification**: For tokens above the minimum threshold, the hook identifies the best yielding strategy within the user's risk profile.
4. **Opportunity Notification**: The hook emits an event with the optimization opportunity.
5. **Auto-Deployment (Optional)**: If the user has opted in for auto-deployment, the hook can automatically allocate funds to the identified strategy.

## User Configuration

Users can customize their yield optimization preferences:

- **Opt-In Status**: Users must explicitly opt in to use the service.
- **Risk Tolerance**: Set a maximum risk level (1-10) for yield strategies.
- **Maximum Allocation**: Define the maximum amount of tokens to auto-deploy.

## Integration with Other Protocols

The Yield Optimizer Hook is designed to interface with multiple DeFi protocols beyond Silo, including:

- Lending protocols like Aave, Compound, and others
- Automated market makers for liquidity provision
- Yield aggregators and optimizers
- Staking protocols

## Getting Started

To start using the Yield Optimizer Hook:

1. Set your preferences using the `setUserPreference` function:
   ```solidity
   // Example: Opt in with medium risk (5/10) and max allocation of 1000 tokens
   yieldOptimizerHook.setUserPreference(true, 5, 1000e18);
   ```

2. Interact with Silo markets as usual - the hook will automatically identify optimization opportunities.

3. Monitor the `YieldOpportunityFound` events for potential yield strategies.

4. If auto-deployment is enabled, watch for `AutoDeployExecuted` events indicating when your idle tokens are put to work.

## Administrative Features

The hook owner can:

- Add new yield strategies with defined risk levels
- Remove or deactivate strategies
- Update minimum token thresholds for optimization

## Security Considerations

- The hook uses the opt-in model - users must explicitly enable optimization
- User-defined risk parameters and allocation limits provide guardrails
- No automatic rebalancing or liquidation risks
- All actions are executed transparently on-chain with event logging

## Development and Customization

Developers can extend this hook by:

- Adding interfaces to new yield protocols
- Implementing more sophisticated yield calculation mechanisms
- Creating custom risk scoring algorithms
- Building front-end interfaces to visualize optimization opportunities

## License

This project is licensed under the UNLICENSED license. 