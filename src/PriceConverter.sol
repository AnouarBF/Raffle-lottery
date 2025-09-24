// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error PriceConverter__BadPrice();

library PriceConverter {
    function getConversion(
        uint amount,
        AggregatorV3Interface priceFeed
    ) public view returns (uint) {
        uint ethPrice_18 = _getPrice(priceFeed);
        uint amountUSD_18 = (amount * ethPrice_18) / 1e18;
        uint amountUSD = amountUSD_18 / 1e18;
        return amountUSD;
    }

    function _getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint) {
        (, int price, , , ) = priceFeed.latestRoundData();
        if (price <= 0) revert PriceConverter__BadPrice();
        uint decimal = 18 - priceFeed.decimals();
        uint correctDecimals_18 = uint(price) * (10 ** decimal);
        return correctDecimals_18;
    }
}
