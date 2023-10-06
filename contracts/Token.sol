//SPDX-License-Identifier: Unlicense
pragma solidity >0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20, Ownable {
    uint256 public burnRate; // burn rate multiplied by 10^6
    uint256 public devRate; // dev rate multiplied by 10^6
    address public devAddress;
    mapping(address => bool) public feeWhitelist;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _totalSupply,
        address _devAddress
    ) public ERC20(_tokenName, _tokenSymbol) {
        burnRate = 20000; // 2%
        devRate = 10000; // 1%
        devAddress = _devAddress;
        _mint(msg.sender, _totalSupply);
    }

    // Owner functions

    function addWhitelist(address _addr, bool _feeAllow) external onlyOwner {
        feeWhitelist[_addr] = _feeAllow;
    }

    function setBurnRate(uint256 _rate) external onlyOwner {
        require(_rate < 1000000, "Invalid rate");
        burnRate = _rate;
    }

    function setDevRate(uint256 _rate) external onlyOwner {
        require(_rate < 1000000, "Invalid rate");
        devRate = _rate;
    }

    function setDevAddress(address _addr) external onlyOwner {
        require(_addr != address(0), "Invalid address");
        devAddress = _addr;
    }

    // Transfer

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if (feeWhitelist[_msgSender()] || feeWhitelist[recipient]) {
            uint256 burnAmount = amount.mul(burnRate).div(10**6);
            uint256 devAmount = amount.mul(devRate).div(10**6);
            uint256 finalAmount = amount.sub(
                burnAmount.add(devAmount),
                "Fee exceeds amount"
            );
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), devAddress, devAmount);
            _transfer(_msgSender(), recipient, finalAmount);
        } else {
            _transfer(_msgSender(), recipient, amount);
        }

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (feeWhitelist[sender] || feeWhitelist[recipient]) {
            uint256 burnAmount = amount.mul(burnRate).div(10**6);
            uint256 devAmount = amount.mul(devRate).div(10**6);
            uint256 finalAmount = amount.sub(
                burnAmount.add(devAmount),
                "Fee exceeds amount"
            );
            _burn(sender, burnAmount);
            _transfer(sender, devAddress, devAmount);
            _transfer(sender, recipient, finalAmount);
        } else {
            _transfer(sender, recipient, amount);
        }

        _approve(
            sender,
            _msgSender(),
            allowance(sender, _msgSender()).sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }
}
