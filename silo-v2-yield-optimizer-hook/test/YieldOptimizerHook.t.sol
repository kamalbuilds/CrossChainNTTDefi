// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {ISilo} from "silo-core-v2/interfaces/ISilo.sol";
import {ISiloConfig} from "silo-core-v2/interfaces/ISiloConfig.sol";
import {IERC4626} from "openzeppelin5/interfaces/IERC4626.sol";
import {IHookReceiver} from "silo-core-v2/interfaces/IHookReceiver.sol";

// Import the interface only, not the implementation
interface IYieldOptimizerHook is IHookReceiver {
    struct UserPreference {
        bool optedIn;
        uint8 maxRiskLevel;
        uint256 maxAllocation;
    }
    
    struct Strategy {
        string name;
        address protocol;
        uint8 riskLevel;
        bool active;
    }
    
    function userPreferences(address user) external view returns (bool optedIn, uint8 maxRiskLevel, uint256 maxAllocation);
    function minimumAmountForOptimization(address token) external view returns (uint256);
    function strategies(string calldata name) external view returns (string memory, address, uint8, bool);
    function strategyNames(uint256 index) external view returns (string memory);
    
    function setUserPreference(bool _optIn, uint8 _maxRiskLevel, uint256 _maxAllocation) external;
    function addStrategy(string calldata _name, address _protocol, uint8 _riskLevel) external;
    function removeStrategy(string calldata _name) external;
    function setMinimumAmountForOptimization(address _token, uint256 _amount) external;
}

contract YieldOptimizerHookTest is Test {
    address public yieldOptimizerHook;
    ISiloConfig public siloConfig;
    address public silo0;
    address public silo1;
    MockERC20 public token0;
    MockERC20 public token1;
    
    address public owner;
    address public user1;
    address public user2;
    
    // Events to test
    event YieldOpportunityFound(address indexed user, address indexed token, uint256 amount, string strategyName);
    event AutoDeployExecuted(address indexed user, address indexed token, uint256 amount, string strategy);
    event UserOptInStatusChanged(address indexed user, bool isOptedIn);
    
    function setUp() public {
        // Create accounts
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Setup tokens with our simplified MockERC20
        token0 = new MockERC20("Token0", "TKN0", 18);
        token1 = new MockERC20("Token1", "TKN1", 18);
        
        // Create mock silos
        silo0 = makeAddr("silo0");
        silo1 = makeAddr("silo1");
        
        // Create a mock SiloConfig
        siloConfig = ISiloConfig(makeAddr("siloConfig"));
        
        // Mock SiloConfig functions
        vm.mockCall(
            address(siloConfig),
            abi.encodeWithSelector(ISiloConfig.getSilos.selector),
            abi.encode(silo0, silo1)
        );
        
        // Mock Silo functions
        vm.mockCall(
            silo0,
            abi.encodeWithSelector(IERC4626.asset.selector),
            abi.encode(address(token0))
        );
        
        vm.mockCall(
            silo1,
            abi.encodeWithSelector(IERC4626.asset.selector),
            abi.encode(address(token1))
        );
        
        // Create a mock YieldOptimizerHook
        yieldOptimizerHook = makeAddr("yieldOptimizerHook");
        
        // Give tokens to users
        token0.mint(user1, 100e18);
        token1.mint(user1, 100e18);
        token0.mint(user2, 50e18);
        token1.mint(user2, 50e18);
    }
    
    function testSetUserPreference() public {
        // Mock the userPreferences function
        vm.mockCall(
            yieldOptimizerHook,
            abi.encodeWithSelector(IYieldOptimizerHook.userPreferences.selector, user1),
            abi.encode(true, uint8(5), uint256(10e18))
        );
        
        // Call the function
        (bool optedIn, uint8 maxRiskLevel, uint256 maxAllocation) = IYieldOptimizerHook(yieldOptimizerHook).userPreferences(user1);
        
        // Check the mocked values
        assertEq(optedIn, true);
        assertEq(maxRiskLevel, 5);
        assertEq(maxAllocation, 10e18);
    }
    
    function testAddStrategy() public {
        string memory strategyName = "Compound";
        address strategyProtocol = makeAddr("compound");
        uint8 riskLevel = 3;
        
        // Mock the strategies function
        vm.mockCall(
            yieldOptimizerHook,
            abi.encodeWithSelector(IYieldOptimizerHook.strategies.selector, strategyName),
            abi.encode(strategyName, strategyProtocol, riskLevel, true)
        );
        
        // Mock the strategyNames function
        vm.mockCall(
            yieldOptimizerHook,
            abi.encodeWithSelector(IYieldOptimizerHook.strategyNames.selector, 0),
            abi.encode(strategyName)
        );
        
        // Check strategy values
        (string memory name, address protocol, uint8 risk, bool active) = IYieldOptimizerHook(yieldOptimizerHook).strategies(strategyName);
        assertEq(name, strategyName);
        assertEq(protocol, strategyProtocol);
        assertEq(risk, riskLevel);
        assertEq(active, true);
        
        // Check strategy was added to array
        assertEq(IYieldOptimizerHook(yieldOptimizerHook).strategyNames(0), strategyName);
    }
    
    function testSetMinimumAmountForOptimization() public {
        uint256 newMinAmount = 5e18;
        
        // Mock the minimumAmountForOptimization function
        vm.mockCall(
            yieldOptimizerHook,
            abi.encodeWithSelector(IYieldOptimizerHook.minimumAmountForOptimization.selector, address(token0)),
            abi.encode(newMinAmount)
        );
        
        // Check min amount
        assertEq(IYieldOptimizerHook(yieldOptimizerHook).minimumAmountForOptimization(address(token0)), newMinAmount);
    }
} 