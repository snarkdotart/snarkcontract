pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SnarkDefinitions.sol";
import "./SnarkBaseLib.sol";
import "./SnarkCommonLib.sol";
import "./SnarkLoanLib.sol";


contract SnarkLoan is Ownable, SnarkDefinitions {

    using SnarkBaseLib for address;
    using SnarkCommonLib for address;
    using SnarkLoanLib for address;

    address private _storage;

    event LoanCreated(address indexed loanBidOwner, uint256 loanId);
    event LoanAccepted(address indexed artworkOwner, uint256 loanId, uint256 artworkId);
    event LoanStarted(uint256 loanId);
    event LoanFinished(uint256 loanId);
    event LoanOfArtworkCanceled(uint256 loanId, uint256 artworkId);

    constructor(address storageAddress) public {
        _storage = storageAddress;
    }

    // в аренду может запросить заинтересованный чел
    // в аренду может взять snark
    function createLoan(
        uint256[] artworksIds,
        uint256 startDate,
        uint256 duration
    ) 
        public 
        payable
    {
        // создаем новый запись об аренде
        uint256 loanId = _storage.createLoan(
            artworksIds,
            msg.value,
            startDate,
            duration,
            msg.sender
        );

        // деньги переводим на счет контракта
        if (msg.value > 0) _storage.addPendingWithdrawals(_storage, msg.value);

        // выставляем автоматически согласие для тех токенов,
        // у которых выставлены свойста автоматического принятия запросов на аренду
        bool isAgree = false;
        for (uint256 i = 0; i < artworksIds.length; i++) {
            isAgree = (msg.sender == owner) ? 
                _storage.isArtworkAcceptOfLoanRequestFromSnark(artworksIds[i]) :
                _storage.isArtworkAcceptOfLoanRequestFromOthers(artworksIds[i]);
            // проверить занятость токена... изменить его тип можно только, если он не продается,
            // т.е. если нет оффера или аукциона и не задействован в другом loan
            uint256 saleType = _storage.getSaleTypeToArtwork(artworksIds[i]);
            if (isAgree && saleType == uint256(SaleType.None)) {
                // !!! проверить на количество дней, на которые уже был сдан токен
                // и в случае, если он превышает заданное количество - отклонить !!!
                // !!! ВИДИМО ЛУЧШЕ ДЕЛАТЬ ЭТУ ПРОВЕРКУ ЕЩЕ НА ЭТАПЕ СОЗДАНИЯ ЛОАНА НА Frontend-е
                _acceptLoan(loanId, artworksIds[i], _storage.getOwnerOfArtwork(artworksIds[i]));
            }
        }
        emit LoanCreated(msg.sender, loanId);
    }

    function acceptLoan(uint256 artworkId) public {
        address _ownerOfArtwork = _storage.getOwnerOfArtwork(artworkId);
        uint256 _saleType = _storage.getSaleTypeToArtwork(artworkId);
        uint256 _loanId = _storage.getLoanByArtwork(artworkId);

        require(msg.sender == _ownerOfArtwork, "Only an artwork owner can accept a loan request.");
        require(_saleType == uint256(SaleType.None), "Token must be free");

        _acceptLoan(_loanId, artworkId, _ownerOfArtwork);

        emit LoanAccepted(msg.sender, _loanId, artworkId);
    }

    // только система может запустить лоан в действие по расписанию
    function startLoan(uint256 loanId) public onlyOwner {
        // подсчитываем стоимость одной картины
        uint256 _price = _storage.getLoanPriceOfArtwork(loanId);
        // пробегаемся по всем токенам в лоане и смотрим акцепнут он или нет
        uint256 _totalNumberOfArtworks = _storage.getTotalNumberOfLoanArtworks(loanId);
        uint256 _artworkId;
        bool _isAccepted;
        address _currentOwnerOfArtwork;
        for (uint256 i = 0; i < _totalNumberOfArtworks; i++) {
            _artworkId = _storage.getArtworkFromLoanList(loanId, i);
            _isAccepted = _storage.isArtworkAcceptedForLoan(loanId, _artworkId);
            if (_isAccepted) {
                // если да, то производим трансфер 
                _storage.transferArtwork(
                    _artworkId, 
                    _storage.getOwnerOfArtwork(_artworkId), 
                    _storage.getDestinationWalletOfLoan(loanId)
                );
                // и переводим бабло владельцам за аренду
                if (_price > 0) {
                    _currentOwnerOfArtwork = _storage.getCurrentArtworkOwnerForLoan(loanId, _artworkId);
                    _storage.subPendingWithdrawals(_storage, _price);
                    _storage.addPendingWithdrawals(_currentOwnerOfArtwork, _price);
                }
                // !!!!  при это необходимо перешифровать картины !!!!
                // !!!! вероятно это делать надо со стороны backend-а по приходу события, 
                // а не здесь и сейчас !!!!
            } else {
                // тут надо вернуть сумму за картину обратно, т.к. запрос был не принят
                if (_price > 0) {
                    address _borrower = _storage.getDestinationWalletOfLoan(loanId);
                    _storage.subPendingWithdrawals(_storage, _price);
                    _storage.addPendingWithdrawals(_borrower, _price);

                    // уменьшаем общую стоимость лоана
                    uint256 totalPrice = _storage.getTotalPriceOfLoan(loanId);
                    _storage.setTotalPriceOfLoan(loanId, totalPrice - _price);

                    // удаляем из списка
                    _storage.deleteArtworkFromListOfLoan(loanId, _artworkId);
                    _storage.deleteLoanToArtwork(_artworkId);
                }
            }
        }
        // помечаем, что Loan уже включился и работает
        _storage.setLoanSaleStatus(loanId, uint256(SaleStatus.Active));
        
        emit LoanStarted(loanId);
    }

    // только система может остановить лоан по расписанию
    function stopLoan(uint256 loanId) public onlyOwner {
        _storage.setLoanSaleStatus(loanId, uint256(SaleStatus.Finished));
        // перемещаем все лоаны на место
        uint256 _totalNumberOfArtworks = _storage.getTotalNumberOfLoanArtworks(loanId);
        address _borrower = _storage.getDestinationWalletOfLoan(loanId);
        uint256 _artworkId;
        address _ownerOfArtwork;
        for (uint256 i = 0; i < _totalNumberOfArtworks; i++) {
            _artworkId = _storage.getArtworkFromLoanList(loanId, i);
            _ownerOfArtwork = _storage.getOwnerOfArtwork(_artworkId);
            _storage.deleteLoanToArtwork(_artworkId);
            _storage.setSaleTypeToArtwork(_artworkId, uint256(SaleType.None));
            _storage.transferArtwork(_artworkId, _borrower, _ownerOfArtwork);
        }
        emit LoanFinished(loanId);
    }

    // вызвать может только владелец токена
    function cancelLoanArtwork(uint256 artworkId) public payable {
        address _ownerOfArtwork = _storage.getOwnerOfArtwork(artworkId);
        address _borrower = _storage.getDestinationWalletOfLoan(_loanId);
        require(msg.sender == _ownerOfArtwork, "Only an artwork owner can accept a loan request.");

        // убедиться, что лоан сейчас запущен. если нет, то выход из функции
        uint256 _loanId = _storage.getLoanByArtwork(artworkId);
        uint256 _status = _storage.getLoanSaleStatus(_loanId);
        require(_status == uint256(SaleStatus.Active), "Loan has to be in 'active' status");

        // проверяем сумму, которая была перечислена. Если она меньше той, 
        // что выходит на одну картину для лоана - выход с ошибкой
        uint256 _price = _storage.getLoanPriceOfArtwork(_loanId);
        require(msg.value >= _price, "Payment has to be equal to cost of loan artwork");
        if (_price > 0) {
            _storage.addPendingWithdrawals(_borrower, _price);
        }
        if ((msg.value - _price) > 0) {
            _storage.addPendingWithdrawals(msg.sender, (msg.value - _price));
        }

        // удалить artwork из списка loan
        _storage.deleteArtworkFromListOfLoan(_loanId, artworkId);
        _storage.deleteLoanToArtwork(artworkId);

        _storage.setSaleTypeToArtwork(artworkId, uint256(SaleType.None));
        _storage.declineArtworkForLoan(_loanId, artworkId);
        _storage.transferArtwork(artworkId, _borrower, _ownerOfArtwork);

        emit LoanOfArtworkCanceled(_loanId, artworkId);
    } 

    // автоматическая отдача на уровне токена (при покупке)
    // можно всегда изменить accept artloans
    function _acceptLoan(uint256 loanId, uint256 artworkId, address artworkOwner) internal {
        _storage.setSaleTypeToArtwork(artworkId, uint256(SaleType.Loan));
        _storage.acceptArtworkForLoan(loanId, artworkId);
        _storage.setCurrentArtworkOwnerForLoan(loanId, artworkId, artworkOwner);
    }


}
