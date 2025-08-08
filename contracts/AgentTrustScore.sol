// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AgentTrustScore {
    address public owner;
    address public amocaAdmin;

    // Simple reputation mapping: DID => score (0..100 or arbitrary scale)
    mapping(bytes32 => int256) private score;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AmocaAdminUpdated(address indexed previous, address indexed current);
    event ScoreUpdated(bytes32 indexed targetDID, int256 newScore, int256 delta, bytes32 contextHash);

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }
    modifier onlyAmoca() { require(msg.sender == amocaAdmin, "not AMOCA"); _; }

    constructor(address _amoca) {
        owner = msg.sender;
        amocaAdmin = _amoca;
        emit OwnershipTransferred(address(0), owner);
        emit AmocaAdminUpdated(address(0), _amoca);
    }

    function setAmocaAdmin(address _amoca) external onlyOwner {
        emit AmocaAdminUpdated(amocaAdmin, _amoca);
        amocaAdmin = _amoca;
    }

    function updateScore(bytes32 targetDID, int256 rating, bytes32 contextHash) external onlyAmoca {
        // rating can be positive/negative
        int256 old = score[targetDID];
        int256 newScore = old + rating;
        score[targetDID] = newScore;
        emit ScoreUpdated(targetDID, newScore, rating, contextHash);
    }

    function getScore(bytes32 targetDID) external view returns (int256) {
        return score[targetDID];
    }
}
