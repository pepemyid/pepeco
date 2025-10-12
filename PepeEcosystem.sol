/**
 *Submitted for verification at polygonscan.com on 2025-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PepeEcosystem is IERC20 {
    string public constant name = "Pepe Ecosystem";
    string public constant symbol = "PEPECO";
    uint8 public constant decimals = 18;
    uint256 public constant TOTAL_SUPPLY = 21000000000 * 10**18;
    uint256 public constant INITIAL_SUPPLY = 10000000 * 10**18;
    
    address public constant DEVELOPER_WALLET = 0x2A0440de444bCe7Fc8be2cd3Ee874d00bFB9b8af;
    address public constant POOL_WALLET = 0x9A485bf6543833a0A0740ac694B0782048d3E005;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Gas fee sharing variables
    uint256 public gasFeePercentage = 1000; // 10% in basis points (1000 = 10%)
    uint256 public collectedGasFees;
    uint256 public constant GAS_FEE_CLAIM_THRESHOLD = 0.1 ether; // Minimum 0.1 POL untuk diklaim
    
    // Staking variables
    struct StakingInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lastClaimTime;
        bool isActive;
    }
    
    mapping(address => StakingInfo) public stakings;
    uint256 public constant STAKING_DURATION = 365 days;
    uint256 public constant MIN_STAKING_AMOUNT = 1 ether;
    uint256 public constant STAKING_TAX = 200; // 2%
    uint256 public constant EARLY_UNSTAKE_PENALTY = 2000; // 20%
    
    // Minting schedule
    uint256 public constant MINTING_PERIOD = 90 days;
    uint256 public launchTime;
    
    uint256[] public rewardRates = [
        100 * 10**18,
        50 * 10**18, 
        25 * 10**18,
        12500000000000000000,
        6250000000000000000,
        3125000000000000000,
        1562500000000000000,
        781250000000000000,
        390625000000000000,
        195312500000000000,
        97656250000000000,
        48828125000000000
    ];
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event GasFeeCollected(address indexed from, uint256 feeAmount);
    event GasFeesClaimed(address indexed developer, uint256 amount);
    
    modifier onlyDeveloper() {
        require(msg.sender == DEVELOPER_WALLET, "Only developer can call this");
        _;
    }
    
    constructor() {
        _totalSupply = INITIAL_SUPPLY;
        _balances[DEVELOPER_WALLET] = INITIAL_SUPPLY;
        launchTime = block.timestamp;
        
        emit Transfer(address(0), DEVELOPER_WALLET, INITIAL_SUPPLY);
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        
        // Gas fee sharing - dikumpulkan tapi tidak diambil langsung
        // Fee akan diklaim manual oleh developer ketika cukup threshold
        _collectGasFee(from);
        
        _balances[from] -= amount;
        _balances[to] += amount;
        
        emit Transfer(from, to, amount);
    }
    
    function _collectGasFee(address from) internal {
        // Simulasi pengumpulan gas fee (nilai tetap untuk demo)
        // Dalam implementasi real, ini bisa dihitung berdasarkan complexitas transaksi
        uint256 simulatedGasFee = 0.00003 ether; // Contoh: 0.00003 BNB
        
        // Pastikan pengirim memiliki cukup BNB untuk gas fee
        if (address(from).balance >= simulatedGasFee) {
            collectedGasFees += simulatedGasFee;
            emit GasFeeCollected(from, simulatedGasFee);
        }
    }
    
    // Fungsi untuk developer mengklaim gas fee yang terkumpul
    function claimGasFees() external onlyDeveloper {
        require(collectedGasFees >= GAS_FEE_CLAIM_THRESHOLD, "Below threshold");
        require(address(this).balance >= collectedGasFees, "Insufficient contract balance");
        
        uint256 feesToClaim = collectedGasFees;
        collectedGasFees = 0;
        
        payable(DEVELOPER_WALLET).transfer(feesToClaim);
        emit GasFeesClaimed(DEVELOPER_WALLET, feesToClaim);
    }
    
    // Fungsi untuk melihat gas fee yang terkumpul
    function getCollectedGasFees() external view returns (uint256) {
        return collectedGasFees;
    }
    
    // Update gas fee percentage (hanya developer)
    function setGasFeePercentage(uint256 newPercentage) external onlyDeveloper {
        require(newPercentage <= 2000, "Max 20%"); // Maksimal 20%
        gasFeePercentage = newPercentage;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }
    
    // Staking functions
    function stake() external payable {
        require(msg.value >= MIN_STAKING_AMOUNT, "Minimum staking amount is 1 POL");
        require(!stakings[msg.sender].isActive, "Already staking");
        
        uint256 tax = (msg.value * STAKING_TAX) / 10000;
        uint256 stakingAmount = msg.value - tax;
        
        payable(POOL_WALLET).transfer(tax);
        
        stakings[msg.sender] = StakingInfo({
            amount: stakingAmount,
            startTime: block.timestamp,
            lastClaimTime: block.timestamp,
            isActive: true
        });
        
        emit Staked(msg.sender, stakingAmount);
    }
    
    function unstake() external {
        StakingInfo storage staking = stakings[msg.sender];
        require(staking.isActive, "No active staking");
        
        uint256 amountToSend = staking.amount;
        
        if (block.timestamp < staking.startTime + STAKING_DURATION) {
            uint256 penalty = (staking.amount * EARLY_UNSTAKE_PENALTY) / 10000;
            amountToSend -= penalty;
            payable(POOL_WALLET).transfer(penalty);
        }
        
        _claimRewards(msg.sender);
        delete stakings[msg.sender];
        payable(msg.sender).transfer(amountToSend);
        
        emit Unstaked(msg.sender, amountToSend);
    }
    
    function claimRewards() external {
        require(stakings[msg.sender].isActive, "No active staking");
        _claimRewards(msg.sender);
    }
    
    function _claimRewards(address user) internal {
        StakingInfo storage staking = stakings[user];
        uint256 pendingRewards = getPendingRewards(user);
        
        if (pendingRewards > 0) {
            require(_totalSupply + pendingRewards <= TOTAL_SUPPLY, "Max supply reached");
            
            _totalSupply += pendingRewards;
            _balances[user] += pendingRewards;
            staking.lastClaimTime = block.timestamp;
            
            emit RewardsClaimed(user, pendingRewards);
            emit Transfer(address(0), user, pendingRewards);
        }
    }
    
    function getPendingRewards(address user) public view returns (uint256) {
        StakingInfo memory staking = stakings[user];
        if (!staking.isActive) return 0;
        
        uint256 currentPeriod = getCurrentPeriod();
        uint256 lastClaimPeriod = (staking.lastClaimTime - launchTime) / MINTING_PERIOD;
        
        if (currentPeriod <= lastClaimPeriod) return 0;
        
        uint256 rewardRate = getCurrentRewardRate();
        uint256 periodsPassed = currentPeriod - lastClaimPeriod;
        
        return (staking.amount * rewardRate * periodsPassed) / MIN_STAKING_AMOUNT;
    }
    
    function getCurrentPeriod() public view returns (uint256) {
        return (block.timestamp - launchTime) / MINTING_PERIOD;
    }
    
    function getCurrentRewardRate() public view returns (uint256) {
        uint256 yearsPassed = (block.timestamp - launchTime) / (4 * 365 days);
        if (yearsPassed >= rewardRates.length) {
            return 0;
        }
        return rewardRates[yearsPassed];
    }
    
    function getStakingInfo(address user) external view returns (uint256 amount, uint256 startTime, uint256 lastClaimTime, bool isActive) {
        StakingInfo memory staking = stakings[user];
        return (staking.amount, staking.startTime, staking.lastClaimTime, staking.isActive);
    }
    
    // Emergency functions
    function emergencyWithdrawBNB() external onlyDeveloper {
        payable(DEVELOPER_WALLET).transfer(address(this).balance);
    }
    
    function emergencyWithdrawToken(address tokenAddress) external onlyDeveloper {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(DEVELOPER_WALLET, balance);
    }
    
    receive() external payable {}
}
