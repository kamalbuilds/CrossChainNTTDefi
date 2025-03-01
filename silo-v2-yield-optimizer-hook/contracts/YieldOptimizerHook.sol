// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IHookReceiver} from "silo-core-v2/interfaces/IHookReceiver.sol";
import {ISiloConfig} from "silo-core-v2/interfaces/ISiloConfig.sol";
import {ISilo} from "silo-core-v2/interfaces/ISilo.sol";
import {IERC20} from "openzeppelin5/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin5/interfaces/IERC4626.sol";
import {SafeERC20} from "openzeppelin5/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin5/access/Ownable.sol";

import {Hook} from "silo-core-v2/lib/Hook.sol";
import {BaseHookReceiver} from "silo-core-v2/utils/hook-receivers/_common/BaseHookReceiver.sol";
import {GaugeHookReceiver} from "silo-core-v2/utils/hook-receivers/gauge/GaugeHookReceiver.sol";
import {PartialLiquidation} from "silo-core-v2/utils/hook-receivers/liquidation/PartialLiquidation.sol";

/// @title Yield Optimizer Hook for Silo Protocol
/// @notice This hook detects idle tokens in a user's wallet after they interact with Silo
/// and provides paths to optimize yield by deploying them to the best available options.
/// @dev Includes ability to track user preferences, analyze yield strategies, and 
/// automatically deploy idle funds with user permission
contract YieldOptimizerHook is GaugeHookReceiver, PartialLiquidation {
    using Hook for uint256;
    using Hook for bytes;
    using SafeERC20 for IERC20;

    // Events
    event YieldOpportunityFound(address indexed user, address indexed token, uint256 amount, string strategyName);
    event AutoDeployExecuted(address indexed user, address indexed token, uint256 amount, string strategy);
    event UserOptInStatusChanged(address indexed user, bool isOptedIn);
    event MinimumAmountUpdated(address indexed token, uint256 amount);
    event StrategyAdded(string indexed name, address indexed protocol, uint8 riskLevel);
    event StrategyRemoved(string indexed name);
    
    // Errors
    error YieldOptimizerHook_Unauthorized();
    error YieldOptimizerHook_InvalidAmount();
    error YieldOptimizerHook_StrategyNotFound();
    error YieldOptimizerHook_StrategyAlreadyExists();
    error YieldOptimizerHook_UserNotOptedIn();
    error YieldOptimizerHook_ZeroAddress();

    // Structs
    struct Strategy {
        string name;        // Name of the strategy
        address protocol;   // Address of the protocol to interact with
        uint8 riskLevel;    // Risk level from 1 (lowest) to 10 (highest)
        bool active;        // Whether this strategy is currently active
    }
    
    struct UserPreference {
        bool optedIn;       // Whether user has opted in for auto-deployment
        uint8 maxRiskLevel; // Maximum risk level the user is willing to accept
        uint256 maxAllocation; // Maximum amount of tokens to auto-deploy
    }

    // State variables
    address public hookOwner;
    mapping(address => UserPreference) public userPreferences;
    mapping(address => uint256) public minimumAmountForOptimization; // Minimum token amount that makes sense to optimize
    mapping(string => Strategy) public strategies; // Available yield strategies
    string[] public strategyNames; // Names of all strategies

    /// @dev Initialize the hook
    /// @param _siloConfig Address of the Silo config
    /// @param _data ABI encoded parameters (owner address)
    function initialize(ISiloConfig _siloConfig, bytes calldata _data) external initializer override {
        // Do not remove initialization lines for fully compatible functionality
        (address _owner) = abi.decode(_data, (address));

        // Initialize hook with SiloConfig address
        BaseHookReceiver.__BaseHookReceiver_init(_siloConfig);
        
        // Initialize GaugeHookReceiver
        GaugeHookReceiver.__GaugeHookReceiver_init(_owner);
        
        // Initialize YieldOptimizerHook
        __YieldOptimizerHook_init(_owner);
    }

    /// @dev Initialize the YieldOptimizerHook
    /// @param _owner Address of the owner who can manage strategies
    function __YieldOptimizerHook_init(address _owner) internal {
        require(_owner != address(0), "YieldOptimizerHook: owner cannot be zero address");
        hookOwner = _owner;
        
        // Set reasonable minimum amounts for common tokens
        // These would be updated based on current gas costs and token values
        minimumAmountForOptimization[address(0)] = 0.01 ether; // ETH
        
        // Setup initial hooks configuration for after actions
        // We want to monitor deposits, withdrawals, borrows, and repays
        _configureHooks();
    }
    
    /// @dev Setup hook configuration for all actions we want to monitor
    function _configureHooks() internal {
        (address silo0, address silo1) = siloConfig.getSilos();
        
        // Configure hooks for the first silo
        if (silo0 != address(0)) {
            uint256 hooksBefore = _getHooksBefore(silo0);
            uint256 hooksAfter = _getHooksAfter(silo0);
            
            // Add all actions we need to monitor
            hooksAfter = hooksAfter.addAction(Hook.depositAction(ISilo.CollateralType.Protected));
            hooksAfter = hooksAfter.addAction(Hook.depositAction(ISilo.CollateralType.Collateral));
            hooksAfter = hooksAfter.addAction(Hook.withdrawAction(ISilo.CollateralType.Protected));
            hooksAfter = hooksAfter.addAction(Hook.withdrawAction(ISilo.CollateralType.Collateral));
            hooksAfter = hooksAfter.addAction(Hook.BORROW);
            hooksAfter = hooksAfter.addAction(Hook.REPAY);
            
            _setHookConfig(silo0, uint24(hooksBefore), uint24(hooksAfter));
        }
        
        // Configure hooks for the second silo
        if (silo1 != address(0)) {
            uint256 hooksBefore = _getHooksBefore(silo1);
            uint256 hooksAfter = _getHooksAfter(silo1);
            
            // Add all actions we need to monitor
            hooksAfter = hooksAfter.addAction(Hook.depositAction(ISilo.CollateralType.Protected));
            hooksAfter = hooksAfter.addAction(Hook.depositAction(ISilo.CollateralType.Collateral));
            hooksAfter = hooksAfter.addAction(Hook.withdrawAction(ISilo.CollateralType.Protected));
            hooksAfter = hooksAfter.addAction(Hook.withdrawAction(ISilo.CollateralType.Collateral));
            hooksAfter = hooksAfter.addAction(Hook.BORROW);
            hooksAfter = hooksAfter.addAction(Hook.REPAY);
            
            _setHookConfig(silo1, uint24(hooksBefore), uint24(hooksAfter));
        }
    }
    
    /// @inheritdoc IHookReceiver
    function hookReceiverConfig(address _silo)
        external
        view
        override(BaseHookReceiver, IHookReceiver)
        returns (uint24 hooksBefore, uint24 hooksAfter)
    {
        // Do not remove this line if you want fully compatible functionality
        (hooksBefore, hooksAfter) = _hookReceiverConfig(_silo);
    }

    /// @notice Called before an action is executed
    /// @param _silo Address of the Silo
    /// @param _action Action being executed
    /// @param _input Encoded input data for the action
    function beforeAction(address _silo, uint256 _action, bytes calldata _input)
        external
        override(IHookReceiver)
    {
        // This hook doesn't need to do anything before actions
        // We only care about analyzing after actions are completed
    }

    /// @notice Called after an action (deposit, withdraw, borrow, repay) is executed
    /// @param _silo Address of the Silo
    /// @param _action Action being executed
    /// @param _inputAndOutput Encoded input and output data from the action
    function afterAction(address _silo, uint256 _action, bytes calldata _inputAndOutput)
        public
        override(GaugeHookReceiver, IHookReceiver)
    {
        // Execute the GaugeHookReceiver afterAction first
        GaugeHookReceiver.afterAction(_silo, _action, _inputAndOutput);
        
        // Check for idle tokens based on the action type
        if (Hook.matchAction(_action, Hook.depositAction(ISilo.CollateralType.Protected)) ||
            Hook.matchAction(_action, Hook.depositAction(ISilo.CollateralType.Collateral))) {
            _handleAfterDeposit(_inputAndOutput);
        } else if (Hook.matchAction(_action, Hook.withdrawAction(ISilo.CollateralType.Protected)) ||
                  Hook.matchAction(_action, Hook.withdrawAction(ISilo.CollateralType.Collateral))) {
            _handleAfterWithdraw(_inputAndOutput);
        } else if (Hook.matchAction(_action, Hook.BORROW)) {
            _handleAfterBorrow(_inputAndOutput);
        } else if (Hook.matchAction(_action, Hook.REPAY)) {
            _handleAfterRepay(_inputAndOutput);
        }
    }
    
    /// @dev Handle idle token detection after deposit
    function _handleAfterDeposit(bytes calldata _inputAndOutput) internal {
        Hook.AfterDepositInput memory input = _inputAndOutput.afterDepositDecode();
        _checkForIdleTokens(input.receiver);
    }
    
    /// @dev Handle idle token detection after withdraw
    function _handleAfterWithdraw(bytes calldata _inputAndOutput) internal {
        Hook.AfterWithdrawInput memory input = _inputAndOutput.afterWithdrawDecode();
        _checkForIdleTokens(input.receiver);
    }
    
    /// @dev Handle idle token detection after borrow
    function _handleAfterBorrow(bytes calldata _inputAndOutput) internal {
        Hook.AfterBorrowInput memory input = _inputAndOutput.afterBorrowDecode();
        _checkForIdleTokens(input.receiver);
    }
    
    /// @dev Handle idle token detection after repay
    function _handleAfterRepay(bytes calldata _inputAndOutput) internal {
        Hook.AfterRepayInput memory input = _inputAndOutput.afterRepayDecode();
        _checkForIdleTokens(input.borrower);
    }
    
    /// @dev Check for idle tokens in a user's wallet and suggest optimizations
    function _checkForIdleTokens(address _user) internal {
        // Skip if user hasn't opted in
        if (!userPreferences[_user].optedIn) return;
        
        // Get tokens from both silos
        (address silo0, address silo1) = siloConfig.getSilos();
        address asset0 = IERC4626(silo0).asset();
        address asset1 = IERC4626(silo1).asset();
        
        // Check for idle tokens of both assets
        _checkTokenBalance(_user, asset0);
        _checkTokenBalance(_user, asset1);
        
        // In a real implementation, you would also check for other common tokens
        // that the user might want to optimize
    }
    
    /// @dev Check token balance and find optimization opportunities
    function _checkTokenBalance(address _user, address _token) internal {
        // Check user's token balance
        uint256 balance = IERC20(_token).balanceOf(_user);
        
        // Skip if balance is below threshold
        if (balance < minimumAmountForOptimization[_token]) return;
        
        // Find best strategy for this token and user's risk preference
        (string memory strategyName, uint256 expectedYield) = _findBestStrategy(_token, userPreferences[_user].maxRiskLevel);
        
        // Emit event for opportunity
        emit YieldOpportunityFound(_user, _token, balance, strategyName);
        
        // If auto-deployment is enabled, deploy funds
        if (userPreferences[_user].optedIn && bytes(strategyName).length > 0) {
            uint256 amountToAllocate = _calculateAllocationAmount(_user, balance);
            if (amountToAllocate > 0) {
                // In a real implementation, this would execute the strategy
                // through a secure mechanism with user approval
                emit AutoDeployExecuted(_user, _token, amountToAllocate, strategyName);
            }
        }
    }
    
    /// @dev Calculate how much to allocate based on user preferences
    function _calculateAllocationAmount(address _user, uint256 _balance) internal view returns (uint256) {
        uint256 maxAllocation = userPreferences[_user].maxAllocation;
        return maxAllocation < _balance ? maxAllocation : _balance;
    }
    
    /// @dev Find the best strategy for the given token and risk level
    /// @return strategyName Name of the best strategy
    /// @return expectedYield Expected yield (APY) multiplied by 1e18
    function _findBestStrategy(address _token, uint8 _maxRiskLevel) internal view returns (string memory strategyName, uint256 expectedYield) {
        // In a real implementation, this would query on-chain or use an oracle
        // to find the highest yielding options within user's risk tolerance
        
        // Placeholder logic
        uint256 highestYield = 0;
        
        for (uint256 i = 0; i < strategyNames.length; i++) {
            Strategy memory strategy = strategies[strategyNames[i]];
            
            // Skip inactive strategies or those above user's risk tolerance
            if (!strategy.active || strategy.riskLevel > _maxRiskLevel) continue;
            
            // In reality, we would calculate the actual expected yield here
            uint256 yield = 5e16; // 5% APY as an example
            
            if (yield > highestYield) {
                highestYield = yield;
                strategyName = strategy.name;
            }
        }
        
        return (strategyName, highestYield);
    }
    
    // ====== User-facing functions ======
    
    /// @notice Allow users to opt in or out of yield optimization
    /// @param _optIn Whether to opt in (true) or out (false)
    /// @param _maxRiskLevel Maximum risk level user is willing to accept (1-10)
    /// @param _maxAllocation Maximum amount to auto-allocate
    function setUserPreference(bool _optIn, uint8 _maxRiskLevel, uint256 _maxAllocation) external {
        require(_maxRiskLevel <= 10, "Risk level must be between 1 and 10");
        
        userPreferences[msg.sender] = UserPreference({
            optedIn: _optIn,
            maxRiskLevel: _maxRiskLevel,
            maxAllocation: _maxAllocation
        });
        
        emit UserOptInStatusChanged(msg.sender, _optIn);
    }
    
    // ====== Admin functions ======
    
    /// @notice Add a new yield strategy
    /// @param _name Strategy name
    /// @param _protocol Address of the protocol
    /// @param _riskLevel Risk level (1-10)
    function addStrategy(string calldata _name, address _protocol, uint8 _riskLevel) external {
        if (msg.sender != hookOwner) revert YieldOptimizerHook_Unauthorized();
        if (_protocol == address(0)) revert YieldOptimizerHook_ZeroAddress();
        if (_riskLevel == 0 || _riskLevel > 10) revert YieldOptimizerHook_InvalidAmount();
        if (strategies[_name].protocol != address(0)) revert YieldOptimizerHook_StrategyAlreadyExists();
        
        strategies[_name] = Strategy({
            name: _name,
            protocol: _protocol,
            riskLevel: _riskLevel,
            active: true
        });
        
        strategyNames.push(_name);
        emit StrategyAdded(_name, _protocol, _riskLevel);
    }
    
    /// @notice Remove a yield strategy
    /// @param _name Strategy name
    function removeStrategy(string calldata _name) external {
        if (msg.sender != hookOwner) revert YieldOptimizerHook_Unauthorized();
        if (strategies[_name].protocol == address(0)) revert YieldOptimizerHook_StrategyNotFound();
        
        strategies[_name].active = false;
        emit StrategyRemoved(_name);
    }
    
    /// @notice Update the minimum amount for optimization
    /// @param _token Token address
    /// @param _amount Minimum amount
    function setMinimumAmountForOptimization(address _token, uint256 _amount) external {
        if (msg.sender != hookOwner) revert YieldOptimizerHook_Unauthorized();
        
        minimumAmountForOptimization[_token] = _amount;
        emit MinimumAmountUpdated(_token, _amount);
    }
} 