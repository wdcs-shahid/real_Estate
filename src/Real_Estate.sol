//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;
import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Real_estate is ERC1155("") {
    uint256 private key = 0;
    IERC20 public usdt;

    struct Investor {
        address investor;
        uint256 amount;
        uint256 timestamp;
    }

    struct Property {
        address propertyOwner;
        uint256 askUSDT;
        uint256 recievedUSDT;
        string propertyAddress;
        uint256 addreward;
        uint256 investorCount;
        mapping(uint256 => Investor) investors;
    }

    constructor(address USDT) {
        usdt = IERC20(USDT); //usdt.balanceOf , usdt.allowance , usdt.transferFrom
    }

    mapping(uint256 => Property) public properties;

    function registerProperty(
        uint256 _askUSDT,
        string memory _propertyAddress
    ) external {
        _mint(msg.sender, key, _askUSDT, "");
        properties[key].propertyOwner = msg.sender;
        properties[key].askUSDT = _askUSDT;
        properties[key].propertyAddress = _propertyAddress;
        key++;
    }

    function invest(uint id, uint256 _amount) external {
        properties[id].investors[properties[id].investorCount] = Investor({
            investor: msg.sender,
            amount: _amount,
            timestamp: block.timestamp
        });
        require(usdt.balanceOf(msg.sender) >= _amount, "Insufficient Balance");

        require(
            usdt.allowance(msg.sender, address(this)) >= _amount,
            "Insufficient Allowance"
        );
        Property storage land = properties[id];
        require(land.askUSDT >= _amount, "Required Investment Amount is Less");
        land.askUSDT -= _amount;
        land.recievedUSDT += _amount;
        usdt.transferFrom(msg.sender, properties[id].propertyOwner, _amount);
        _safeTransferFrom(land.propertyOwner, msg.sender, id, _amount, "");
        properties[id].investorCount++;
    }

    function addReward(uint _key, uint _addReward) external {
        Property storage getProperty = properties[_key];
        require(
            getProperty.askUSDT == 0,
            "You can add rewards after achieving askUSDT amount"
        );
        require(
            getProperty.propertyOwner == msg.sender,
            "Only Owner Can Add Rewards"
        );
        require(
            usdt.balanceOf(msg.sender) >= _addReward,
            "Insufficient Balance"
        );
        require(
            usdt.allowance(msg.sender, address(this)) >= _addReward,
            "Insufficient Allowance"
        );
        usdt.transferFrom(msg.sender, address(this), _addReward);
        getProperty.addreward = _addReward;
    }

    function checkInvestor(
        uint256 _key,
        address _investor
    ) internal view returns (bool, uint) {
        Property storage getExistingInvestor = properties[_key];
        for (uint i; i < getExistingInvestor.investorCount; i++) {
            if (_investor == properties[_key].investors[i].investor) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function getReward(uint _key) external {
        (bool success, uint investorId) = checkInvestor(_key, msg.sender);
        require(success, "Investor not found");
        Property storage rewardInfo = properties[_key];
        Investor storage getInvestor = properties[_key].investors[investorId];
        require(
            rewardInfo.askUSDT == 0,
            "You can get rewards after achieving askUSDT amount"
        );
        require(getInvestor.timestamp + 30 days >= block.timestamp, "You can only withdraw after 30 days of your investment");
        getInvestor.timestamp = block.timestamp;
        uint reward = (rewardInfo.addreward * getInvestor.amount) /
            rewardInfo.recievedUSDT;
        usdt.transfer(msg.sender, reward);
    }
}
