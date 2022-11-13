// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
}

contract InstaArb is Ownable{

    address[] public routers;
    address[] public tokens;
    address[] public stables;

    function addRouters(address[] memory _routers) external onlyOwner {
        for(uint i=0; i< _routers.length; i++){
            routers.push(_routers[i]);
        }
    }

    function addTokens(address[] memory _tokens) external onlyOwner {
        for(uint i=0; i< _tokens.length; i++){
            tokens.push(_tokens[i]);
        }
    }

    function addStables(address[] memory _stables) external onlyOwner {
        for(uint i=0; i< _stables.length; i++){
            stables.push(_stables[i]);
        }
    }

    function swap(address router, address tokenIn, address tokenOut, uint256 _amount) private {
        IERC20(tokenIn).approve(router, _amount);
        address[] memory path;
        path = new address[](2);
        path[0]=tokenIn;
        path[1]=tokenOut;
        IUniswapV2Router(router).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp+300);
    }

    function getAmountsOut(address router, address _token1, address _token2, uint256 _amount) public view returns(uint256) {
        address[] memory path;
        path = new address[](2);
        path[0]=_token1;
        path[1]=_token2;
        uint256 result=0;
        try IUniswapV2Router(router).getAmountsOut(_amount, path) returns(uint256[] memory amountOutMins){
            result = amountOutMins[path.length-1];
        }catch{

        }
        return result;
    }

    function estimateDualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external view returns(uint256){
        uint256 amt1 = getAmountsOut(_router1, _token1, _token2, _amount);
        uint256 amt2 = getAmountsOut(_router2, _token1, _token2, amt1);
        return amt2;
    }

    function dualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external onlyOwner {
        uint256 startBal = IERC20(_token1).balanceOf(address(this));
        swap(_router1, _token1, _token2, _amount);
        uint256 balAfterSwap1 = IERC20(_token2).balanceOf(address(this));
        swap(_router2, _token2, _token1, balAfterSwap1);
        uint256 endBal = IERC20(_token1).balanceOf(address(this));
        require(endBal > startBal, "Loss in Txn");
    }

    function instaSearch(address _router, address _baseAsset, uint256 _amount) external view returns(uint256, address, address, address){
        uint256 amtBack;
        address token1;
        address token2;
        address token3;
        for(uint i1; i1 < tokens.length; i1++){
            for(uint i2=0; i2 < stables.length; i2++){
                for(uint i3=0; i3<tokens.length; i3++){
                    amtBack = getAmountsOut(_router, _baseAsset, tokens[i1], _amount);
                    amtBack = getAmountsOut(_router, tokens[i1], stables[i2], amtBack);
                    amtBack = getAmountsOut(_router, stables[i2], tokens[i3], amtBack);
                    amtBack = getAmountsOut(_router, tokens[i3], _baseAsset, amtBack);
                    if(amtBack > _amount){
                        token1 = tokens[i1];
                        token2 = tokens[i2];
                        token3 = tokens[i3];
                        break;
                    }
                }
            }
        }
        return (amtBack, token1, token2, token3);
    }

    function instaTrade(address _router, address _token1, address _token2, address _token3, address _token4 , uint256 _amount) external onlyOwner {
        uint256 startBal = IERC20(_token1).balanceOf(address(this));
        uint256 tradeAbleAmount;
        uint256 token2InitialBalance = IERC20(_token2).balanceOf(address(this));
        uint256 token3InitialBalance = IERC20(_token3).balanceOf(address(this)); 
        uint256 token4InitialBalance = IERC20(_token4).balanceOf(address(this)); 
        swap(_router, _token1, _token2, _amount);
        tradeAbleAmount = IERC20(_token2).balanceOf(address(this));
        swap(_router, _token2, _token3, tradeAbleAmount - token2InitialBalance);
        tradeAbleAmount = IERC20(_token3).balanceOf(address(this));
        swap(_router, _token3, _token4, tradeAbleAmount - token3InitialBalance);
        tradeAbleAmount = IERC20(_token4).balanceOf(address(this));
        swap(_router, _token4, _token1, tradeAbleAmount - token4InitialBalance);
        uint256 endBal = IERC20(_token1).balanceOf(address(this));
        require(endBal > startBal, "Loss in trade");
    }

    function getBalance(address _tokenAddress) external view returns(uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function recoverETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverTokens(address _tokenAddress) external onlyOwner {
        uint256 amount = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(msg.sender, amount);
    }

}