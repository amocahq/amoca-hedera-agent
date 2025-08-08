// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {ConsentManager} from "../contracts/ConsentManager.sol";
import {AgentTrustScore} from "../contracts/AgentTrustScore.sol";
import {ResearchSponsor} from "../contracts/ResearchSponsor.sol";
import {DataIncentive} from "../contracts/DataIncentive.sol";

contract ERC20Mock {
    string public name = "Mock";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    function mint(address to, uint256 amount) external { balanceOf[to] += amount; }
    function approve(address spender, uint256 amount) external returns (bool) { allowance[msg.sender][spender] = amount; return true; }
    function transfer(address to, uint256 amount) external returns (bool) { require(balanceOf[msg.sender] >= amount, "bal"); balanceOf[msg.sender] -= amount; balanceOf[to] += amount; return true; }
    function transferFrom(address from, address to, uint256 amount) external returns (bool) { require(allowance[from][msg.sender] >= amount, "allow"); require(balanceOf[from] >= amount, "bal"); allowance[from][msg.sender] -= amount; balanceOf[from] -= amount; balanceOf[to] += amount; return true; }
}

contract ContractsTest is Test {
    ConsentManager cm;
    AgentTrustScore ats;
    ResearchSponsor rs;
    DataIncentive di;
    ERC20Mock token;

    address amoca = address(0xA11CE);
    address sponsor = address(0x500);
    address researcher = address(0xBEEF);
    address patient1 = address(0xB0B);

    function setUp() public {
        cm = new ConsentManager(amoca);
        ats = new AgentTrustScore(amoca);
        token = new ERC20Mock();
        di = new DataIncentive(address(token), amoca);
        rs = new ResearchSponsor(amoca);

        token.mint(sponsor, 1_000_000 ether);
        vm.prank(sponsor);
        token.approve(address(rs), type(uint256).max);
    }

    function testConsentLogAndVerify() public {
        vm.prank(amoca);
        uint256 id = cm.logConsent(bytes32("pat"), bytes32("spon"), bytes32("data"));
        (bool ok, uint256 got) = cm.verifyConsent(bytes32("pat"), bytes32("data"));
        assertTrue(ok);
        assertEq(got, id);
    }

    function testTrustScore() public {
        vm.prank(amoca);
        ats.updateScore(bytes32("alice"), 10, bytes32("ctx"));
        assertEq(ats.getScore(bytes32("alice")), 10);
    }

    function testResearchSponsorFlow() public {
        string[] memory mnames = new string[](2);
        uint256[] memory mamounts = new uint256[](2);
        mnames[0] = "Cohort Formed"; mamounts[0] = 100 ether;
        mnames[1] = "Final Report"; mamounts[1] = 150 ether;

        vm.prank(sponsor);
        uint256 id = rs.createSponsorship("SMA criteria", address(token), 500 ether, mnames, mamounts, bytes32("pub"));

        vm.prank(sponsor);
        rs.lockFunds(id, 400 ether);

        vm.prank(amoca);
        rs.assignResearcher(id, researcher);

        vm.prank(amoca);
        rs.releaseMilestonePayment(id, 0, address(0));
        assertEq(token.balanceOf(researcher), 100 ether);

        address[] memory recs = new address[](1); recs[0] = patient1;
        uint256[] memory amts = new uint256[](1); amts[0] = 50 ether;
        vm.prank(amoca);
        rs.releasePatientRewards(id, recs, amts);
        assertEq(token.balanceOf(patient1), 50 ether);
    }

    function testDataIncentive() public {
        token.mint(address(this), 1000 ether);
        token.approve(address(di), type(uint256).max);
        di.fund(500 ether);

        // setRewardRate is onlyOwner; owner is the deployer (address(this))
        di.setRewardRate(bytes32("MRI"), 1 ether);
        assertEq(di.calculatePatientReward(bytes32("MRI"), 5), 5 ether);

        vm.prank(amoca);
        di.distribute(patient1, 5 ether, "reward");
        assertEq(token.balanceOf(patient1), 5 ether);
    }
}
