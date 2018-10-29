pragma solidity ^0.4.24;

import "../SnarkStorage.sol";
import "../openzeppelin/SafeMath.sol";


library SnarkBaseExtraLib {
    using SafeMath for uint256;

    function setTokenToParticipantApproving(
        address storageAddress, 
        uint256 tokenId, 
        address participant, 
        bool consent
    ) 
        public
    {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("tokenToParticipantApproving", tokenId, participant)),
            consent
        );
    }

    function addProfitShareScheme(
        address storageAddress,
        address schemeOwner,
        address[] participants,
        uint256[] profits
    )
        public
        returns (uint256 schemeId) 
    {
        schemeId = SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfProfitShareSchemes")) + 1;
        SnarkStorage(storageAddress).setUint(keccak256("totalNumberOfProfitShareSchemes"), schemeId);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfParticipantsForProfitShareScheme", schemeId)), 
            participants.length
        );
        for (uint256 i = 0; i < participants.length; i++) {
            SnarkStorage(storageAddress).setAddress(
                keccak256(abi.encodePacked("participantAddressForProfitShareScheme", schemeId, i)), 
                participants[i]);
            SnarkStorage(storageAddress).setUint(
                keccak256(abi.encodePacked("participantProfitForProfitShareScheme", schemeId, i)), 
                profits[i]);
            bool isParticipantRegistered = isParticipantRegisteredForSchemeOwner(
                storageAddress, schemeOwner, participants[i]
            );
            if (!isParticipantRegistered) {
                registerParticipantForSchemeOwner(storageAddress, schemeOwner, participants[i]);
                uint index = getNumberOfUniqueParticipantsForOwner(storageAddress, schemeOwner);
                SnarkStorage(storageAddress).setAddress(
                    keccak256(abi.encodePacked("participantByIndexForOwner", schemeOwner, index)),
                    participants[i]
                );
                SnarkStorage(storageAddress).setUint(
                    keccak256(abi.encodePacked("numberOfUniqueParticipantsForOwner", schemeOwner)),
                    index.add(1)
                );
            }
        }

        uint256 numberOfSchemesForOwner = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfProfitShareSchemesForOwner", schemeOwner)));
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfProfitShareSchemesForOwner", schemeOwner)), 
            numberOfSchemesForOwner + 1
        );
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("profitShareSchemeIdsForOwner", schemeOwner, numberOfSchemesForOwner)),
            schemeId
        );
    }

    function registerParticipantForSchemeOwner(address storageAddress, address schemeOwner, address participant)
        public 
    {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("isParticipantAlreadyRegisteredForOnwer", schemeOwner, participant)),
            true
        );
    }

    /*** GET ***/
    function getTokenProfitShareSchemeId(address storageAddress, uint256 tokenId) public view
        returns (uint256 profitShareSchemeId)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("token", "profitShareSchemeId", tokenId))
        );
    }

    function isParticipantRegisteredForSchemeOwner(address storageAddress, address schemeOwner, address participant)
        public
        view
        returns (bool)
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("isParticipantAlreadyRegisteredForOnwer", schemeOwner, participant))
        );
    }

    function getTotalNumberOfProfitShareSchemes(address storageAddress) public view returns (uint256 number) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfProfitShareSchemes"));
    }

    function getNumberOfParticipantsForProfitShareScheme(address storageAddress, uint256 schemeId) 
        public 
        view 
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfParticipantsForProfitShareScheme", schemeId)));
    }

    function getParticipantOfProfitShareScheme(address storageAddress, uint256 schemeId, uint256 index) 
        public
        view
        returns (
            address participant, 
            uint256 profit
        )
    {
        participant = SnarkStorage(storageAddress).addressStorage(
            keccak256(abi.encodePacked("participantAddressForProfitShareScheme", schemeId, index)) 
        );

        profit = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("participantProfitForProfitShareScheme", schemeId, index))
        );
    }

    function getNumberOfProfitShareSchemesForOwner(address storageAddress, address schemeOwner) 
        public 
        view 
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfProfitShareSchemesForOwner", schemeOwner)));
    }

    function getProfitShareSchemeIdForOwner(address storageAddress, address schemeOwner, uint256 index)
        public
        view
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("profitShareSchemeIdsForOwner", schemeOwner, index)));
    }

    function doesProfitShareSchemeIdBelongsToOwner(address storageAddress, address schemeOwner, uint256 schemeId)
        public
        view
        returns (bool)
    {
        bool doesBelongs = false;
        uint256 currentSchemeId;
        uint256 numberOfSchemes = getNumberOfProfitShareSchemesForOwner(storageAddress, schemeOwner);
        for (uint256 i = 0; i < numberOfSchemes; i++) {
            currentSchemeId = getProfitShareSchemeIdForOwner(storageAddress, schemeOwner, i);
            if (currentSchemeId == schemeId) {
                doesBelongs = true;
                break;
            }
        }
        return doesBelongs;
    }

    function getNumberOfUniqueParticipantsForOwner(address storageAddress, address schemeOwner)
        public 
        view 
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfUniqueParticipantsForOwner", schemeOwner))
        );
    }

    function getParticipantByIndexForOwner(address storageAddress, address schemeOwner, uint256 index)
        public
        view
        returns (address)
    {
        return SnarkStorage(storageAddress).addressStorage(
            keccak256(abi.encodePacked("participantByIndexForOwner", schemeOwner, index))
        );
    }

    function getListOfUniqueParticipantsForOwner(address storageAddress, address schemeOwner)
        public
        view
        returns (address[])
    {
        uint256 _count = getNumberOfUniqueParticipantsForOwner(storageAddress, schemeOwner);
        address[] memory participants = new address[](_count);
        for (uint256 i = 0; i < _count; i++) {
            participants[i] = getParticipantByIndexForOwner(storageAddress, schemeOwner, i);
        }
        return participants;
    }
    ///////// TOKEN CALENDAR FUNCTIONS /////////
    // one day datetime = 86400000
    // function reservePeriodInTokenCalendar(startDay, countDay)
    // function checkIfPeriodIsReservedInTokenCalendar(startDay, countDay) - check every day
    // function deletePeriodFromTokenCalendar(startDay, countDay) or (type {loan} + type id {loan id})
    // function getTypeOf
    // function getCountTokensReservedOnTheDay
    ///////// REQUEST LIST FUNCTIONS /////////
}