// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ConsentManager {
    struct ConsentLog {
        uint256 id;
        bytes32 patientDID;   // hash/bytes32 representation of DID
        bytes32 sponsorDID;   // hash/bytes32 representation of DID
        bytes32 dataHash;     // hash of consent VC or data scope
        uint64 timestamp;
        bool revoked;
    }

    address public owner;
    address public amocaAdmin;

    uint256 public nextId;
    mapping(uint256 => ConsentLog) public consents;
    // For quick lookup of the latest consent per (patientDID,dataHash)
    mapping(bytes32 => uint256) private latestConsentByKey;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AmocaAdminUpdated(address indexed previous, address indexed current);
    event ConsentLogged(uint256 indexed id, bytes32 indexed patientDID, bytes32 indexed sponsorDID, bytes32 dataHash, uint64 timestamp);
    event ConsentRevoked(uint256 indexed id, bytes32 indexed patientDID, bytes32 dataHash);

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

    function logConsent(
        bytes32 patientDID,
        bytes32 sponsorDID,
        bytes32 dataHash
    ) external onlyAmoca returns (uint256 id) {
        id = ++nextId;
        ConsentLog storage c = consents[id];
        c.id = id;
        c.patientDID = patientDID;
        c.sponsorDID = sponsorDID;
        c.dataHash = dataHash;
        c.timestamp = uint64(block.timestamp);
        c.revoked = false;

        bytes32 key = keccak256(abi.encodePacked(patientDID, dataHash));
        latestConsentByKey[key] = id;

        emit ConsentLogged(id, patientDID, sponsorDID, dataHash, c.timestamp);
    }

    function revokeConsent(uint256 id) external onlyAmoca {
        ConsentLog storage c = consents[id];
        require(c.id != 0, "unknown id");
        require(!c.revoked, "already");
        c.revoked = true;
        emit ConsentRevoked(id, c.patientDID, c.dataHash);
    }

    function verifyConsent(bytes32 patientDID, bytes32 dataHash) external view returns (bool valid, uint256 id) {
        bytes32 key = keccak256(abi.encodePacked(patientDID, dataHash));
        id = latestConsentByKey[key];
        if (id == 0) return (false, 0);
        ConsentLog storage c = consents[id];
        if (c.revoked) return (false, id);
        return (true, id);
    }
}
