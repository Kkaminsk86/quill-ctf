// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import {ERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ISwapV2Router02} from "../interface.sol";

contract Token is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint initialMint
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialMint);
    }
}

contract Arbitrage is Test {
    address[] tokens;
    Token Atoken;
    Token Btoken;
    Token Ctoken;
    Token Dtoken;
    Token Etoken;
    Token Ftoken;
    address owner = makeAddr("owner");
    address arbitrageMan = makeAddr("arbitrageMan");
    ISwapV2Router02 router =
        ISwapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function addL(address first, address second, uint aF, uint aS) internal {
        router.addLiquidity(
            address(first),
            address(second),
            aF,
            aS,
            aF,
            aS,
            owner,
            block.timestamp
        );
    }

    function setUp() public {
        vm.createSelectFork(
            "https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY"
        );
        vm.startPrank(owner);
        Atoken = new Token("Atoken", "ATK", 100 ether);
        tokens.push(address(Atoken));
        Btoken = new Token("Btoken", "BTK", 100 ether);
        tokens.push(address(Btoken));
        Ctoken = new Token("Ctoken", "CTK", 100 ether);
        tokens.push(address(Ctoken));
        Dtoken = new Token("Dtoken", "DTK", 100 ether);
        tokens.push(address(Dtoken));
        Etoken = new Token("Etoken", "ETK", 100 ether);
        tokens.push(address(Etoken));

        Atoken.approve(address(router), 100 ether);
        Btoken.approve(address(router), 100 ether);
        Ctoken.approve(address(router), 100 ether);
        Dtoken.approve(address(router), 100 ether);
        Etoken.approve(address(router), 100 ether);

        addL(address(Atoken), address(Btoken), 17 ether, 10 ether);
        addL(address(Atoken), address(Ctoken), 11 ether, 7 ether);
        addL(address(Atoken), address(Dtoken), 15 ether, 9 ether);
        addL(address(Atoken), address(Etoken), 21 ether, 5 ether);
        addL(address(Btoken), address(Ctoken), 36 ether, 4 ether);
        addL(address(Btoken), address(Dtoken), 13 ether, 6 ether);
        addL(address(Btoken), address(Etoken), 25 ether, 3 ether);
        addL(address(Ctoken), address(Dtoken), 30 ether, 12 ether);
        addL(address(Ctoken), address(Etoken), 10 ether, 8 ether);
        addL(address(Dtoken), address(Etoken), 60 ether, 25 ether);

        Btoken.transfer(arbitrageMan, 5 ether);
        vm.stopPrank();
    }

    function testHack() public {
        vm.startPrank(arbitrageMan);
        uint tokensBefore = Btoken.balanceOf(arbitrageMan);
        Btoken.approve(address(router), 5 ether);

        // 1. Swap from Btoken to Dtoken. Ratio in pair 13/6
        swapTokens(address(Btoken), address(Dtoken), 5 ether);

        // 2. Swap all Dtokens to Ctokens. Ratio in pair 12/30
        Dtoken.approve(address(router), type(uint256).max);
        swapTokens(
            address(Dtoken),
            address(Ctoken),
            Dtoken.balanceOf(arbitrageMan)
        );

        // 3. Swap all Ctokens to Btokens. Ratio in pair 4/36
        emit log_named_decimal_uint(
            "Btoken amount before swap from Ctoken",
            Btoken.balanceOf(arbitrageMan),
            Btoken.decimals()
        );
        Ctoken.approve(address(router), type(uint256).max);
        swapTokens(
            address(Ctoken),
            address(Btoken),
            Ctoken.balanceOf(arbitrageMan)
        );
        emit log_named_decimal_uint(
            "Btoken amount after swap from Ctoken",
            Btoken.balanceOf(arbitrageMan),
            Btoken.decimals()
        );

        uint tokensAfter = Btoken.balanceOf(arbitrageMan);
        assertGt(tokensAfter, tokensBefore);
    }

    // Helper function for swapping tokens
    function swapTokens(address from, address to, uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        router.swapExactTokensForTokens(
            amount,
            0,
            path,
            arbitrageMan,
            block.timestamp
        );
    }
}
