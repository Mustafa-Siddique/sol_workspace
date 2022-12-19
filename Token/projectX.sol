// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract projectX{
    mapping(address=>uint256) private balances;

    mapping(address=>mapping(address=>uint256)) private allowances;

    mapping(address=>bool) private isExcludedFromFee;
    mapping(address=>bool) private isExcluded;
    address[] private excluded;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed to, uint256 value);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    uint256 private totalSupply;
    uint8 public decimals = 18;

    address private developmentWallet;
    address private marketingWallet;
    address public owner;

    string public name;
    string public symbol;

    uint256 public taxFee = 20;
    uint256 private previousTaxFee = taxFee;
    uint256 public devFee = 20;
    uint256 private previousDevFee = devFee;
    uint256 public liquidityFee = 20;
    uint256 private previousLiquidityFee = liquidityFee;
    
    IPancakeRouter02 public immutable pancakeV2Router;
    address public immutable pancakeV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 maxTxAmount = totalSupply / 40;
    uint256 numTokensSellToAddToLiquidity = totalSupply / 7500;

    constructor(string memory _name, string memory _symbol, uint256 supply, address _devWallet, address _marketing){
        name = _name;
        symbol = _symbol;
        totalSupply = supply;
        owner = msg.sender;
        developmentWallet = _devWallet;
        marketingWallet = _marketing;
        isExcludedFromFee[owner] = true;
        isExcludedFromFee[address(this)] = true;
        IPancakeRouter02 _pancakeV2Router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakeV2Pair = IPancakeFactory(_pancakeV2Router.factory())
            .createPair(address(this), _pancakeV2Router.WETH());
        pancakeV2Router = _pancakeV2Router;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You should be owner of the contract to call this function.");
        _;
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function balanceOf(address wallet) public view returns(uint256){
        return balances[wallet];
    }

    function transfer(address recipient, uint256 amount) public returns(bool){
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view returns(uint256){
        return allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public returns(bool){
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns(bool){
        _transfer(sender, recipient, amount);
        uint256 allowedTokens = allowances[sender][msg.sender];
        if(allowedTokens >= amount){
            allowedTokens = allowedTokens - amount;
            _approve(sender, msg.sender, allowedTokens);
        }
        else{
            revert("Error: Transfer amount is greater than allowance.");
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool){
        uint256 allowedTokens = allowances[msg.sender][spender];
        allowedTokens = allowedTokens + addedValue;
        _approve(msg.sender, spender, allowedTokens);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool){
        uint256 allowedTokens = allowances[msg.sender][spender];
        if(allowedTokens >= subtractedValue){
            allowedTokens = allowedTokens - subtractedValue;
            _approve(msg.sender, spender, allowedTokens);
        }
        else{
            revert("Error: Decreased allowance below zero.");
        }
        return true;
    }

    function excludeFromFee(address wallet) public {
        require(msg.sender == owner, "You're not authorised to access this function.");
        isExcludedFromFee[wallet] = true;
    }

    function includeInFee(address wallet) public {
        require(msg.sender == owner, "You're not authorised to access this function.");
        isExcludedFromFee[wallet] = false;
    }

    function setTaxFeePercentage(uint256 _taxFee) external onlyOwner{
        taxFee = _taxFee;
    }

    function setDevFeePercentage(uint256 _devFee) external onlyOwner{
        devFee = _devFee;
    }

    function setLiquidityFeePercentage(uint256 _liquidityFee) external onlyOwner{
        liquidityFee = _liquidityFee;
    }

    function removeAllFee() private {
        if(taxFee == 0 && liquidityFee == 0) return;
        previousTaxFee = taxFee;
        previousDevFee = devFee;
        previousLiquidityFee = liquidityFee;
        taxFee = 0;
        devFee = 0;
        liquidityFee = 0;
    }

    function restoreAllFee() private {
        taxFee = previousTaxFee;
        devFee = previousDevFee;
        liquidityFee = previousLiquidityFee;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Error: Sender should not be a zero address.");
        require(recipient != address(0), "Error: Recipient should not be a zero address.");

        uint256 senderBalance = balances[sender];
        if(senderBalance >= amount){
            senderBalance = senderBalance - amount;
            balances[sender] = senderBalance;
            uint256 recipientBalance = balances[recipient];
            recipientBalance = recipientBalance + amount;
            balances[recipient] = recipientBalance;
            emit Transfer(sender, recipient, amount);
        }
        else {
            revert("Transfer amount is greater than Balance.");
        }
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "Error: Owner can never be a zero address.");
        require(spender != address(0), "Error: Spender can never be a zero address.");
        allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

}