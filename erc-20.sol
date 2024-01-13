// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract CustomERC20Token {
    event Transfer(address indexed from, address indexed tom, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    string constant public name = "CustomTokenName";
    string constant public symbol = "CTN";
    uint8 constant public decimal = 18;
    
    uint256 public total_supply;

    address immutable public deployer;

    constructor(address deployer_address) {
        deployer = deployer_address;
    }

    mapping (address => uint256) public addressTokenAmount;
    mapping (address => mapping (address => uint256)) public transferAllowance;

    function getFreeToken() public returns(bool) {
        addressTokenAmount[msg.sender] += 1e18;
        return true;
    }

    function calculateTransactionFee(uint256 amount) private pure returns(uint256) {
        return amount / 100;
    }

    function sendFeeToDeployer(address chargee, uint256 amount) private returns(bool) {
        addressTokenAmount[chargee] -= amount;
        addressTokenAmount[deployer] += amount;
        return true;
    }

    function withdraw(address from, address to, uint256 amount) private returns(bool) {
        uint256 chargeFee = calculateTransactionFee(amount);
        require(addressTokenAmount[from] >= amount + chargeFee, "ERC20: Insufficient balance amount");
        
        addressTokenAmount[from] -= (amount + chargeFee);
        addressTokenAmount[to] += amount;
        if (!sendFeeToDeployer(from, chargeFee)) {
            revert();
        }
        
        emit Transfer(from, to, amount);
        
        return true;
    }

    function transfer(address receiver, uint256 amount) external returns(bool) {
        if (!withdraw(msg.sender, receiver, amount)) {
            revert();
        }
        
        return true;
    }

    function transferFrom(address owner, address receiver, uint256 amount) external returns(bool) {
        require(transferAllowance[owner][msg.sender] >= amount, "Transaction failed: allowance amount restriction");

        if (!withdraw(owner, receiver, amount)) {
            revert();
        }

        transferAllowance[owner][msg.sender] -= amount;
        emit Approval(owner, msg.sender, transferAllowance[owner][msg.sender]);

        return true;
    }

    function approve(address spender, uint256 amount) external returns(bool) {
        emit Approval(msg.sender, spender, amount);

        transferAllowance[msg.sender][spender] += amount;
        return true;
    }
}
