// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library Constants {
    uint8 constant AUCTION_MODE_NONE = 0;
    uint8 constant AUCTION_MODE_NORMAL = 1;
    uint8 constant AUCTION_MODE_PRE = 2;
    uint8 constant DIGITS_OF_CODE = 6;
    string constant REVERT_TRANSFER_FAILED = "NFTMarket::transfer failed";
    string constant REVERT_NOT_OWNER = "NFTMarket::not owner";
    string constant REVERT_NOT_APPROVED = "NFTMarket::not approved";
    string constant REVERT_DUPLICATED_ASK = "NFTMarket::duplicated ask";
    string constant REVERT_NOT_A_CREATOR_OF_ASK =
        "NFTMarket::not a creator of the ask";
    string constant REVERT_NOT_A_CREATOR_OF_BID =
        "NFTMarket::not a creator of the bid";
    string constant REVERT_NOT_WHITELIST_NFT = "NFTMarket::not whitelist nft";
    string constant REVERT_NOT_WHITELIST_ADMIN =
        "NFTMarket::not allowed pre autction list address ";
    string constant REVERT_BID_TOO_LOW = "NFTMarket::bid too low";
    string constant REVERT_BID_EXPIRED = "NFTMarket::bid expired";
    string constant REVERT_NOT_TOP_BIDER = "NFTMarket::not top bider";
    string constant REVERT_AUCTION_WRONG_TIME = "NFTMarket::auction wrong time";
    string constant REVERT_AUCTION_NOT_END = "NFTMarket::auction not end";
    string constant REVERT_AUCTION_HAS_END = "NFTMarket::auction has ended";
    string constant REVERT_ASK_DOES_NOT_EXIST = "NFTMarket::ask does not exist";
    string constant REVERT_ASK_NOT_AUCTION = "NFTMarket::ask is not auction";
    string constant REVERT_ASK_CANNOT_BE_AUCTION =
        "NFTMarket::ask cannot be auction mode";
    string constant REVERT_ASK_EXPIRED = "NFTMarket::ask expired";
    string constant REVERT_CLAIM_ERROR = "NFTMarket::not allowed for claim";
    string constant REVERT_BID_AUCTION_REFUND_ERROR =
        "NFTMarket::auction bid refund error";
    string constant REVERT_BID_DOES_NOT_EXIST = "NFTMarket::bid does not exist";
    string constant REVERT_BID_DEADLINE_ERROR =
        "NFTMarket::bid deadline must be greater than auction end time";
    string constant REVERT_CANT_BID_OWN_ASK = "NFTMarket::cant bid yourself";
    string constant REVERT_BID_CANCEL_FORBID =
        "NFTMarket::cancel bid forbidden";
    string constant REVERT_CANT_ACCEPT_OWN_ASK =
        "NFTMarket::cant accept own ask";
    string constant REVERT_ASK_SELLER_NOT_OWNER =
        "NFTMarket::ask creator not owner";
    string constant REVERT_INSUFFICIENT_ETHER =
        "NFTMarket::insufficient ether sent";
    string constant REVERT_INSUFFICIENT_VALUE = "NFTMarket::insufficient value";
    string constant REVERT_ZERO_BALANCE = "NFTMarket::zero balance";
    string constant REVERT_NOT_DIRECT_SALE = "NFTMarket::not direct sale";
    string constant REVERT_WRONG_TIME_SET =
        "NFTMarket::endTime must be greater than startTime";
    string constant REVERT_NOT_CREATOR_OF_INVITE_CODE =
        "NFTMarket::not creator of invite code";
    string constant REVERT_CLAIM_DOMAIN_FAILED =
        "NFTMarket::claim domain failed";
    string constant REVERT_ASK_AUCTION_PRICE_TOO_LOW =
        "NFTMarket::ask pre auction starting price too low";
    string constant REVERT_ASK_PRE_AUCTION_SUFFIX_NOT_ALLOWED =
        "NFTMarket::ask pre auction suffix not allowed";
    string constant REVERT_AUCTION_REWARD_CLAIM_ERROR =
        "NFTMarket::no rewards can be claimed";
    string constant REVERT_ASK_ENDTIME_NOT_ALLOWED_EXCEED_DOMAIN_EXPIRE =
        "NFTMarket::ask endtime not allowed to exceed domain expire time";
    bytes32 constant HASH_ZERO =
        0x0000000000000000000000000000000000000000000000000000000000000000;

    string constant INSCRIPTION_OP_DEPLOY = "deploy";
    string constant INSCRIPTION_OP_MINT = "Mint";
    string constant INSCRIPTION_OP_TRANSFER = "Transfer";

    string constant TRADE_EVENT_LIST = "list";
    string constant TRADE_EVENT_UNLIST = "unlist";
    string constant TRADE_EVENT_UPDATE = "update";
    string constant TRADE_EVENT_SOLD = "sold";
    string constant TRADE_EVENT_BUY = "buy";
}
