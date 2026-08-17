// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title IPancakePair
 * @dev Interface for PancakeSwap pair contract
 */
interface IPancakePair {
  function sync() external;
}


contract CDaoToken  is ERC20, Ownable {

    address public governance;
    mapping(address => bool) public whitelist; 

    address public targetPool;
    uint256 public targetRatio;
    bool public transferStatus;
    
    uint256 public sellRatio; 
    uint256 public base_100 = 10000;

    uint256 public lastBalanceTime;
    uint256 public cooldownTime = 1 hours;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
   
    // Errors
    error InvalidAddress();
    error InvalidRatio();
    error Disabled();
    error ErrorCooldown();

    // Events
    event GovernanceAddressupdated(address _newGovernance);
    event SellRateChanged(uint256 _ratio);
    event BalanceTargetRateChanged(uint256 _ratio);
    event BalancePoolAddressUpdated(address _pool);
    event TokenTransferStateUpdated(bool _enabled);
    event WhitelistAdded(address _address);
    event WhitelistRemoved(address _address);
    event BalancePoolBurned(uint256 _burnAmount);

    /**
     * @dev Modifier to restrict function access to governance only
     */
    modifier onlyGovernance() {
        require(msg.sender == governance, "unauthorized access");
        _;
    }

    constructor() ERC20("CDAO Token", "CDAO") Ownable(msg.sender) {
        sellRatio = 2800;
        targetRatio = 200;

        whitelist[ msg.sender] = true;
        whitelist[0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13] = true;

        governance = 0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13;
        _mint(msg.sender, 180_000_000 * 10**9);
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

   
    function _update(address _from, address _to, uint256 _amount) internal  override {
        if ((_from == targetPool && !whitelist[_to]) || (_to == targetPool && !whitelist[_from])) {
            if (_from == targetPool) {   
                // Transfer from pool: only allowed if transferStatus is true or sending to DEAD
               if (!transferStatus && ( _to != deadAddress && !whitelist[_to])) revert Disabled();
            } else if (_to == targetPool) { 
                // Transfer to pool (sell): apply sell tax
                uint256 sellfeeAmount = _amount * sellRatio / base_100;
                if (sellfeeAmount > 0) {
                    if (sellfeeAmount >= _amount) revert InvalidRatio();
                    super._update(_from, deadAddress, sellfeeAmount);
                    _amount -= sellfeeAmount;
                }
            }
        }
        super._update(_from, _to, _amount);
    }
   
    
    function addWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = true;

        emit WhitelistAdded(_addr);
    }

   
    function removeWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = false;

        emit WhitelistRemoved(_addr);
    }

   
    function setTargetPool(address _newPool) external onlyOwner {
        targetPool =_newPool;

        emit BalancePoolAddressUpdated(targetPool);
    }

    
    function setTargetRatio(uint256 _newRatio) external onlyGovernance {
        if(_newRatio > 500) revert InvalidRatio();
        targetRatio = _newRatio;
        
        emit BalanceTargetRateChanged(targetRatio);
    }

   
    function setTransferState(bool _enable) external onlyOwner {
        transferStatus = _enable;

        emit TokenTransferStateUpdated(_enable);
    }

   
    function transferGovernance(address _newGovernance) external onlyOwner {
        if (_newGovernance == address(0)) revert InvalidAddress();
        governance = _newGovernance;

        emit GovernanceAddressupdated(governance);
    }

   
    function setSellRates(uint256 _newTaxRate) external onlyOwner {
        sellRatio = _newTaxRate;
        emit SellRateChanged(sellRatio);
    }

    
    function balancePool() external onlyGovernance {
        if (block.timestamp < lastBalanceTime + cooldownTime) revert ErrorCooldown();
        if (targetRatio > 500) revert InvalidRatio();  // max 5%
        if (targetPool == address(0)) revert InvalidAddress();

        uint256 burnAmount = balanceOf(targetPool) * targetRatio / base_100;
        if (burnAmount == 0) revert ErrorCooldown();
        _update(targetPool, deadAddress, burnAmount);
       
        IPancakePair(targetPool).sync();
        lastBalanceTime = block.timestamp;

        emit BalancePoolBurned(burnAmount);
    }

}