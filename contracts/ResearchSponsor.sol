// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./interfaces.sol";

contract ResearchSponsor {
    struct Milestone {
        string name;
        uint256 amount; // amount of token to release on completion
        bool released;
    }

    struct Sponsorship {
        address sponsor;
        string criteria;
        IERC20 token; // $MDAI or other ERC-20 mapped on Hedera EVM
        uint256 totalBudget;
        uint256 lockedAmount;
        address researcher;
        bytes32 statusHash; // e.g., hash of HCS message PUBLISHED
        Milestone[] milestones;
        bool canceled;
    }

    address public owner;
    address public amocaAdmin; // AMOCA orchestrator address allowed to verify milestones

    uint256 public nextId;
    mapping(uint256 => Sponsorship) public sponsorships;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AmocaAdminUpdated(address indexed previous, address indexed current);
    event SponsorshipCreated(uint256 indexed id, address indexed sponsor, address token, uint256 totalBudget, string criteria);
    event FundsLocked(uint256 indexed id, uint256 amount);
    event ResearcherAssigned(uint256 indexed id, address indexed researcher);
    event MilestoneReleased(uint256 indexed id, uint256 indexed milestoneIndex, string name, uint256 amount, address researcher);
    event PatientRewardsReleased(uint256 indexed id, uint256 totalAmount, address[] recipients, uint256[] amounts);
    event SponsorshipCanceled(uint256 indexed id);

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

    function createSponsorship(
        string calldata criteria,
        address token,
        uint256 totalBudget,
        string[] calldata milestoneNames,
        uint256[] calldata milestoneAmounts,
        bytes32 statusHash
    ) external returns (uint256 id) {
        require(totalBudget > 0, "budget=0");
        require(token != address(0), "token=0");
        require(milestoneNames.length == milestoneAmounts.length, "mismatch");
        require(milestoneNames.length > 0, "no milestones");

        id = ++nextId;
        Sponsorship storage s = sponsorships[id];
        s.sponsor = msg.sender;
        s.criteria = criteria;
        s.token = IERC20(token);
        s.totalBudget = totalBudget;
        s.statusHash = statusHash;

        uint256 sum;
        for (uint256 i = 0; i < milestoneNames.length; i++) {
            s.milestones.push(Milestone({name: milestoneNames[i], amount: milestoneAmounts[i], released: false}));
            sum += milestoneAmounts[i];
        }
        require(sum <= totalBudget, "milestones>budget");

        emit SponsorshipCreated(id, msg.sender, token, totalBudget, criteria);
    }

    function lockFunds(uint256 id, uint256 amount) external {
        Sponsorship storage s = sponsorships[id];
        require(msg.sender == s.sponsor, "not sponsor");
        require(!s.canceled, "canceled");
        require(amount > 0, "amount=0");
        require(s.lockedAmount + amount <= s.totalBudget, "exceeds budget");
        require(s.token.transferFrom(msg.sender, address(this), amount), "transferFrom failed");
        s.lockedAmount += amount;
        emit FundsLocked(id, amount);
    }

    function assignResearcher(uint256 id, address researcher) external onlyAmoca {
        Sponsorship storage s = sponsorships[id];
        require(!s.canceled, "canceled");
        s.researcher = researcher;
        emit ResearcherAssigned(id, researcher);
    }

    function releaseMilestonePayment(uint256 id, uint256 milestoneIndex, address researcherOverride) external onlyAmoca {
        Sponsorship storage s = sponsorships[id];
        require(!s.canceled, "canceled");
        require(milestoneIndex < s.milestones.length, "bad index");
        Milestone storage m = s.milestones[milestoneIndex];
        require(!m.released, "already released");
        require(s.lockedAmount >= m.amount, "insufficient locked");
        address recipient = researcherOverride == address(0) ? s.researcher : researcherOverride;
        require(recipient != address(0), "no researcher");
        m.released = true;
        s.lockedAmount -= m.amount;
        require(s.token.transfer(recipient, m.amount), "transfer failed");
        emit MilestoneReleased(id, milestoneIndex, m.name, m.amount, recipient);
    }

    function releasePatientRewards(
        uint256 id,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyAmoca {
        Sponsorship storage s = sponsorships[id];
        require(!s.canceled, "canceled");
        require(recipients.length == amounts.length, "mismatch");
        uint256 total;
        for (uint256 i = 0; i < amounts.length; i++) total += amounts[i];
        require(s.lockedAmount >= total, "insufficient locked");
        s.lockedAmount -= total;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(s.token.transfer(recipients[i], amounts[i]), "transfer failed");
        }
        emit PatientRewardsReleased(id, total, recipients, amounts);
    }

    function cancelSponsorship(uint256 id, address refundTo) external {
        Sponsorship storage s = sponsorships[id];
        require(msg.sender == s.sponsor || msg.sender == owner, "unauthorized");
        require(!s.canceled, "already");
        s.canceled = true;
        if (s.lockedAmount > 0) {
            require(s.token.transfer(refundTo == address(0) ? s.sponsor : refundTo, s.lockedAmount), "refund failed");
            s.lockedAmount = 0;
        }
        emit SponsorshipCanceled(id);
    }
}
