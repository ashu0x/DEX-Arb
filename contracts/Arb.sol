// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

contract Arb is Ownable{

    function swap(address _router, address _tokenIn, address _tokenOut, uint256 _amount) private {
        IERC20(_tokenIn).approve(_router, _amount);
        address[] memory path;
        path = new address[](2);
        path[0]=_tokenIn;
        path[1]=_tokenOut;
        IUniswapRouter(_router).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp + 300);
    }

    function dualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 amount) public onlyOwner {
        uint256 startBal = IERC20(_token1).balanceOf(address(this));
        console.log("Starting Balance Token-1: ",startBal);
        swap(_router1, _token1, _token2, amount);
        uint256 afterswap1bal = IERC20(_token2).balanceOf(address(this));
        console.log("Swap 1 Token-2 Balance: ",afterswap1bal);
        swap(_router2, _token2, _token1, afterswap1bal);
        uint256 finalBal = IERC20(_token1).balanceOf(address(this));
        console.log("Swap 2 Token-1 Balance: ",finalBal);
        require(startBal < finalBal, "Traded For Loss");
    }

    function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256 amounts) {
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        amounts = IUniswapRouter(router).getAmountsOut(_amount, path)[path.length -1];
    }

    function estimateDualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) public view returns (uint256) {
        uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
        uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token1, amtBack1);
        return amtBack2;
    }

    function getBalance(address _tokenContractAddress) public view returns(uint256){
        return IERC20(_tokenContractAddress).balanceOf(address(this));
    }

    function recoverEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverToken(address _tokenAddress) external onlyOwner {
        uint256 amount = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(msg.sender, amount);
    }

}
