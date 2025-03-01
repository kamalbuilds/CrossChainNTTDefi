// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

/**
 * @title MockERC20
 * @dev A simplified ERC20 implementation for testing purposes
 */
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (from != msg.sender) {
            require(allowance[from][msg.sender] >= amount, "MockERC20: insufficient allowance");
            allowance[from][msg.sender] -= amount;
        }
        return _transfer(from, to, amount);
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "MockERC20: transfer from the zero address");
        require(to != address(0), "MockERC20: transfer to the zero address");
        require(balanceOf[from] >= amount, "MockERC20: insufficient balance");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
} 