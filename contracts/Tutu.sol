// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ILXP {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract Tutu is ERC20 {
    address public lxpContract; // LXP contract address
    address public developer; // Developer wallet address
    uint256 public developerBalance;

    mapping(address => uint256) public claimed; // Already claimed amounts for users

    event Claimed(address indexed claimer, uint256 amount);
    event FeePaid(address indexed payer, uint256 amount);

    constructor(
        address _lxpContract,
        address _developer
    ) ERC20("Tutu", "TUTU") {
        lxpContract = _lxpContract;
        developer = _developer;

        ILXP lxp = ILXP(lxpContract);
        uint256 totalSupply = lxp.totalSupply();
        require(totalSupply > 0, "LXP total supply must be greater than 0");

        _mint(address(this), totalSupply); // Mint TUTU to contract address
    }

    modifier sufficientClaimFee() {
        require(
            msg.value == 0.0001 ether,
            "Additional gas fee of 0.0001 ETH required"
        );
        _;
    }

    function claim() external payable sufficientClaimFee {
        // 检查用户是否持有 LXP
        ILXP lxp = ILXP(lxpContract);
        require(
            lxp.balanceOf(msg.sender) > 0,
            "You do not hold any LXP tokens"
        );

        uint256 claimableAmount = getClaimableAmount(msg.sender);
        require(claimableAmount > 0, "No TUTU tokens left to claim");

        developerBalance += msg.value;

        claimed[msg.sender] += claimableAmount;
        _transfer(address(this), msg.sender, claimableAmount);

        emit Claimed(msg.sender, claimableAmount);
    }

    function getClaimableAmount(address account) public view returns (uint256) {
        ILXP lxp = ILXP(lxpContract);
        uint256 lxpBalance = lxp.balanceOf(account);
        require(
            claimed[account] <= lxpBalance,
            "Claimed amount exceeds LXP balance"
        );
        uint256 claimableAmount = lxpBalance - claimed[account];
        return claimableAmount > 0 ? claimableAmount : 0;
    }

    function withdrawDeveloperBalance() external {
        require(msg.sender == developer, "Only developer can withdraw");
        uint256 amount = developerBalance;
        developerBalance = 0;

        payable(developer).transfer(amount);
    }
}
