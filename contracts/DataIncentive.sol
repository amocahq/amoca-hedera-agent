// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./interfaces.sol";

contract DataIncentive {
    address public owner;
    address public amocaAdmin;
    IERC20 public immutable token; // reward token (e.g., $MDAI / HTS mirror)

    // dataType => rate per unit volume (token wei per unit)
    mapping(bytes32 => uint256) public rewardRate;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AmocaAdminUpdated(address indexed previous, address indexed current);
    event RewardRateSet(bytes32 indexed dataType, uint256 rate);
    event Funded(address indexed from, uint256 amount);
    event Distributed(address indexed recipient, uint256 amount, string memo);
    event BatchDistributed(uint256 count, uint256 total, string memo);
    event Withdrawn(address indexed to, uint256 amount);

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }
    modifier onlyAmoca() { require(msg.sender == amocaAdmin, "not AMOCA"); _; }

    constructor(address _token, address _amoca) {
        require(_token != address(0), "token=0");
        owner = msg.sender;
        token = IERC20(_token);
        amocaAdmin = _amoca;
        emit OwnershipTransferred(address(0), owner);
        emit AmocaAdminUpdated(address(0), _amoca);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "owner=0");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setAmocaAdmin(address _amoca) external onlyOwner {
        emit AmocaAdminUpdated(amocaAdmin, _amoca);
        amocaAdmin = _amoca;
    }

    function setRewardRate(bytes32 dataType, uint256 rate) external onlyOwner {
        rewardRate[dataType] = rate;
        emit RewardRateSet(dataType, rate);
    }

    function calculatePatientReward(bytes32 dataType, uint256 volume) external view returns (uint256) {
        return rewardRate[dataType] * volume;
    }

    function fund(uint256 amount) external {
        require(amount > 0, "amount=0");
        require(token.transferFrom(msg.sender, address(this), amount), "transferFrom failed");
        emit Funded(msg.sender, amount);
    }

    function distribute(address recipient, uint256 amount, string calldata memo) external onlyAmoca {
        require(recipient != address(0), "recipient=0");
        require(amount > 0, "amount=0");
        require(token.transfer(recipient, amount), "transfer failed");
        emit Distributed(recipient, amount, memo);
    }

    function batchDistribute(address[] calldata recipients, uint256[] calldata amounts, string calldata memo) external onlyAmoca {
        require(recipients.length == amounts.length, "mismatch");
        uint256 total;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amounts[i]), "transfer failed");
            total += amounts[i];
        }
        emit BatchDistributed(recipients.length, total, memo);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "to=0");
        require(token.transfer(to, amount), "transfer failed");
        emit Withdrawn(to, amount);
    }
}
