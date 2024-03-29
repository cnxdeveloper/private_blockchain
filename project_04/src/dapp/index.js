
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async () => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error, result);
            display('display-wrapper-operational', 'Operational Status', 'Check if contract is operational', [{ label: 'Operational Status', error: error, value: result }]);
        });

        DOM.elid('submit-airline').addEventListener('click', () => {
            let airlineName = DOM.elid('airline-name').value;
            let airlineAddress = DOM.elid('airline-address').value;
            contract.registerAirline(airlineName, airlineAddress, (error, result) => {
                displayTx('display-wrapper-register', [{ label: 'Airline registered Tx', error: error, value: result }]);
                DOM.elid('airline-name').value = "";
                DOM.elid('airline-address').value = "";
            });
        })

        DOM.elid('fund-airlines').addEventListener('click', () => {
            let airlineAddress = DOM.elid('airline-fund-address').value;
            contract.fundAirline(airlineAddress, (error, result) => {
                displayTx('display-wrapper-register', [{ label: 'Airline funded Tx', error: error, value: result }]);
                DOM.elid('airline-fund-address').value = "";
            });
        })

        DOM.elid('is-registered').addEventListener('click', () => {
            let airlineAddress = DOM.elid('airline-fund-address').value;
            contract.isAirlineRegistered(airlineAddress, (error, result) => {
                displayTx('display-wrapper-register', [{ label: 'Is Airline registered', error: error, value: result }]);
                DOM.elid('airline-fund-address').value = "";
            });
        })

        DOM.elid('is-funded').addEventListener('click', () => {
            let airlineAddress = DOM.elid('airline-fund-address').value;
            contract.isAirlineFunded(airlineAddress, (error, result) => {
                displayTx('display-wrapper-register', [{ label: 'Is Airline funded', error: error, value: result }]);
                DOM.elid('airline-fund-address').value = "";
            });
        })
        

        DOM.elid('register-flight').addEventListener('click', () => {
            let flightName = DOM.elid('flight-name').value;
            let airlineAddress = DOM.elid('insurence-airline-address').value;
            let flightTimestamp = DOM.elid('flight-timestamp').value;
            displayTx('display-wrapper-buy', [{ label: 'flightName',  value: flightName }]);
            displayTx('display-wrapper-buy', [{ label: 'airlineAddress',  value: airlineAddress }]);
            displayTx('display-wrapper-buy', [{ label: 'flightTimestamp',  value: flightTimestamp }]);
            contract.registerFlight(flightName, airlineAddress, flightTimestamp, (error, result) => {
                displayTx('display-wrapper-buy', [{ label: 'Register Flight', error: error, value: result }]);
            });
        })

        DOM.elid('submit-buy').addEventListener('click', () => {
            let flightkey = DOM.elid('flight-key').value;
            let insuredAmount = DOM.elid('insurence-amount').value;
            contract.buy(flightkey, insuredAmount, (error, result) => {
                displayTx('display-wrapper-buy', [{ label: 'Insurance purchased Tx', error: error, value: result }]);
                DOM.elid('flight-name').value = "";
                DOM.elid('insurence-airline-address').value = "";
                DOM.elid('flight-timestamp').value = "";
                DOM.elid('insurence-amount').value = "";
            });
        })

        DOM.elid('get-flight-key').addEventListener('click', () => {
            let flightName = DOM.elid('flight-name').value;
            let airlineAddress = DOM.elid('insurence-airline-address').value;
            let flightTimestamp = DOM.elid('flight-timestamp').value;
            contract.getFlightKeybyName(flightName, airlineAddress, flightTimestamp , (error, result) => {
                displayTx('display-wrapper-buy', [{ label: 'Get Flight key', error: error, value: result }]);
                DOM.elid('flight-name').value = "";
                DOM.elid('insurence-airline-address').value = "";
                DOM.elid('flight-timestamp').value = "";
                DOM.elid('flight-key').value = result;
            });
        })

        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flightkey = DOM.elid('flight-key').value;
            contract.fetchFlightStatus(flightkey, (error, result) => {
                displayTx('display-wrapper-buy', [{ label: 'Fetch flight status', error: error, value: result}]);
            });
        })

        DOM.elid('check-balance').addEventListener('click', () => {
            let passengerAddress = DOM.elid('passanger-address').value;
            contract.getPassengerCredit(passengerAddress, (error, result) => {
                displayTx('display-wrapper-passenger-detail', [{ label: 'Credit pending to withdraw', error: error, value: result + ' ETH' }]);
                DOM.elid('passanger-address').value = "";
            });
        })

        DOM.elid('withdraw-balance').addEventListener('click', () => {
            let passengerAddress = DOM.elid('passanger-address').value;
            contract.withdrawCredit(passengerAddress, (error, result) => {
                displayTx('display-wrapper-passenger-detail', [{ label: 'Credit withdrawn', error: error, value: result + ' ETH' }]);
                DOM.elid('passanger-address').value = "";
            });
        });
    });


})();


function display(id, title, description, results) {
    let displayDiv = DOM.elid(id);
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({ className: 'row' }));
        row.appendChild(DOM.div({ className: 'col-sm-4 field' }, result.label));
        row.appendChild(DOM.div({ className: 'col-sm-8 field-value' }, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}

function displayTx(id, results) {
    let displayDiv = DOM.elid(id);
    results.map((result) => {
        let row = displayDiv.appendChild(DOM.div({ className: 'row' }));
        row.appendChild(DOM.div({ className: 'col-sm-3 field' }, result.error ? result.label + " Error" : result.label));
        row.appendChild(DOM.div({ className: 'col-sm-9 field-value' }, result.error ? String(result.error) : String(result.value)));
        displayDiv.appendChild(row);
    })
}
